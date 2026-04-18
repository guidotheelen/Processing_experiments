/*
  Voronoi_Diagram_Creator.pde
  ---------------------------
  Interactive Voronoi diagram generator.

  Controls:
  - Left click empty space: add site
  - Left click near site + drag: move site
  - Right click: remove nearest site
  - R: regenerate random sites
  - + / -: increase or decrease site count
  - E: toggle edge rendering
  - G: toggle distance shading
  - L: one Lloyd relaxation step
  - Space: randomize colors
  - S: save PNG
*/

int canvasWidth = 900;
int canvasHeight = 900;

ArrayList<PVector> sites = new ArrayList<PVector>();
ArrayList<Integer> siteColors = new ArrayList<Integer>();

int siteCount = 50;
float pickRadius = 18;
float edgeWidth = 1.2;

boolean showEdges = true;
boolean useShading = true;
boolean diagramDirty = true;

int draggedSite = -1;
int nextSeed = 1000;

void settings() {
  size(canvasWidth, canvasHeight);
  pixelDensity(1);
}

void setup() {
  colorMode(HSB, 360, 100, 100, 100);
  textFont(createFont("Monospaced", 13));
  generateSites(siteCount);
}

void draw() {
  if (diagramDirty) {
    renderVoronoi();
    diagramDirty = false;
  }

  drawSites();
  drawOverlay();
}

void generateSites(int count) {
  sites.clear();
  siteColors.clear();

  randomSeed(nextSeed++);
  for (int i = 0; i < count; i++) {
    float margin = 24;
    float x = random(margin, width - margin);
    float y = random(margin, height - margin);
    sites.add(new PVector(x, y));
    siteColors.add(newSiteColor(i));
  }

  siteCount = sites.size();
  diagramDirty = true;
}

int newSiteColor(int idx) {
  float golden = 137.508;
  float hue = (idx * golden + random(0, 120)) % 360;
  float sat = random(52, 85);
  float bri = random(68, 96);
  return color(hue, sat, bri);
}

void randomizePalette() {
  for (int i = 0; i < siteColors.size(); i++) {
    siteColors.set(i, newSiteColor(i));
  }
  diagramDirty = true;
}

void renderVoronoi() {
  loadPixels();
  int pixelIndex = 0;

  for (int y = 0; y < height; y++) {
    for (int x = 0; x < width; x++) {
      float best = Float.MAX_VALUE;
      float secondBest = Float.MAX_VALUE;
      int winner = -1;

      for (int i = 0; i < sites.size(); i++) {
        PVector s = sites.get(i);
        float d = manhattanDistance(x, y, s.x, s.y);

        if (d < best) {
          secondBest = best;
          best = d;
          winner = i;
        } else if (d < secondBest) {
          secondBest = d;
        }
      }

      int baseColor = siteColors.get(winner);

      if (showEdges && secondBest < Float.MAX_VALUE) {
        float distanceGap = secondBest - best;
        if (distanceGap < edgeWidth) {
          pixels[pixelIndex++] = color(0, 0, 8);
          continue;
        }
      }

      if (useShading) {
        float nearestDistance = best;
        // Stronger depth: brighter near sites and darker toward cell edges.
        float shade = map(nearestDistance, 0, 420, 1.28, 0.52);
        shade = constrain(shade, 0.44, 1.34);
        pixels[pixelIndex++] = scaleBrightness(baseColor, shade);
      } else {
        pixels[pixelIndex++] = baseColor;
      }
    }
  }

  updatePixels();
}

int scaleBrightness(int c, float factor) {
  float h = hue(c);
  float s = saturation(c);
  float b = brightness(c) * factor;
  return color(h, s, constrain(b, 0, 100));
}

void drawSites() {
  stroke(0, 0, 98, 90);
  strokeWeight(1.6);

  for (int i = 0; i < sites.size(); i++) {
    PVector s = sites.get(i);
    fill(siteColors.get(i));
    circle(s.x, s.y, 8);
  }
}

void drawOverlay() {
  fill(0, 0, 100, 86);
  noStroke();
  rect(14, 14, 460, 84, 8);

  fill(0, 0, 16);
  text(
    "Sites: " + sites.size() +
    "  |  R regenerate  +/- count  E edges  G shading  L relax  Space recolor  S save",
    24, 44
  );
  text("Left: add/drag site   Right: remove nearest site", 24, 68);
}

int nearestSiteIndex(float x, float y) {
  if (sites.size() == 0) {
    return -1;
  }

  float best = Float.MAX_VALUE;
  int winner = 0;

  for (int i = 0; i < sites.size(); i++) {
    PVector s = sites.get(i);
    float d = manhattanDistance(x, y, s.x, s.y);
    if (d < best) {
      best = d;
      winner = i;
    }
  }
  return winner;
}

float manhattanDistance(float x1, float y1, float x2, float y2) {
  return abs(x1 - x2) + abs(y1 - y2);
}

void mousePressed() {
  if (mouseButton == RIGHT) {
    int idx = nearestSiteIndex(mouseX, mouseY);
    if (idx >= 0 && sites.size() > 2) {
      sites.remove(idx);
      siteColors.remove(idx);
      siteCount = sites.size();
      diagramDirty = true;
    }
    return;
  }

  int idx = nearestSiteIndex(mouseX, mouseY);
  if (idx >= 0) {
    PVector s = sites.get(idx);
    if (dist(mouseX, mouseY, s.x, s.y) <= pickRadius) {
      draggedSite = idx;
      return;
    }
  }

  sites.add(new PVector(mouseX, mouseY));
  siteColors.add(newSiteColor(siteColors.size()));
  siteCount = sites.size();
  diagramDirty = true;
}

void mouseDragged() {
  if (draggedSite < 0 || draggedSite >= sites.size()) {
    return;
  }

  PVector s = sites.get(draggedSite);
  s.x = constrain(mouseX, 0, width - 1);
  s.y = constrain(mouseY, 0, height - 1);
  diagramDirty = true;
}

void mouseReleased() {
  draggedSite = -1;
}

void keyPressed() {
  if (key == 'r' || key == 'R') {
    generateSites(siteCount);
  } else if (key == '+' || key == '=') {
    siteCount = min(400, siteCount + 10);
    generateSites(siteCount);
  } else if (key == '-' || key == '_') {
    siteCount = max(2, siteCount - 10);
    generateSites(siteCount);
  } else if (key == 'e' || key == 'E') {
    showEdges = !showEdges;
    diagramDirty = true;
  } else if (key == 'g' || key == 'G') {
    useShading = !useShading;
    diagramDirty = true;
  } else if (key == ' ') {
    randomizePalette();
  } else if (key == 'l' || key == 'L') {
    lloydRelaxationStep();
  } else if (key == 's' || key == 'S') {
    saveFrame("voronoi-######.png");
  }
}

void lloydRelaxationStep() {
  int n = sites.size();
  if (n == 0) {
    return;
  }

  float[] sumX = new float[n];
  float[] sumY = new float[n];
  int[] counts = new int[n];

  int sampleStep = 2;
  for (int y = 0; y < height; y += sampleStep) {
    for (int x = 0; x < width; x += sampleStep) {
      int idx = nearestSiteIndex(x, y);
      sumX[idx] += x;
      sumY[idx] += y;
      counts[idx] += 1;
    }
  }

  for (int i = 0; i < n; i++) {
    if (counts[i] > 0) {
      PVector s = sites.get(i);
      s.x = sumX[i] / counts[i];
      s.y = sumY[i] / counts[i];
    }
  }

  diagramDirty = true;
}
