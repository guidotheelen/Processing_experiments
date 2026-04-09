int squareSize = 1;
int screen_width = 900;
int screen_height = 760;

int uiWidth = 240;

float plateDiameter;
float plateRadius;
float plateCX;
float plateCY;

// Pattern navigation
float patternOffsetX = 0.0;
float patternOffsetY = 0.0;
float panScale = 1.0;
float patternZoom = 1.0;
float minZoom = 0.25;
float maxZoom = 12.0;

boolean panningPattern = false;
float lastMouseX, lastMouseY;

// Chladni parameters
float mFreq = 4.0;
float nFreq = 7.0;
float thickness = 0.020;
int density = 90000;
float contrast = 1.0;
float radialBias = 1.0;

// Sliders
Slider mSlider;
Slider nSlider;
Slider thicknessSlider;
Slider densitySlider;
Slider contrastSlider;
Slider radialBiasSlider;

Slider activeSlider = null;

void settings() {
  size(screen_width, screen_height);
}

void setup() {
  frameRate(30);
  noStroke();
  textFont(createFont("Arial", 14));

  // Circle uses all space left of the UI panel
  plateDiameter = min(width - uiWidth - 30, height - 30) * 0.95;
  plateRadius = plateDiameter * 0.5;
  plateCX = (width - uiWidth) * 0.5;
  plateCY = height * 0.5;

  // Right-side UI panel layout
  float sx = width - uiWidth + 20;
  float sw = uiWidth - 40;
  float sy = 90;
  float gap = 42;

  mSlider = new Slider("M frequency", sx, sy + gap * 0, sw, 0.5, 12.0, mFreq, false);
  nSlider = new Slider("N frequency", sx, sy + gap * 1, sw, 0.5, 12.0, nFreq, false);
  thicknessSlider = new Slider("Thickness", sx, sy + gap * 2, sw, 0.003, 0.060, thickness, false);
  densitySlider = new Slider("Density", sx, sy + gap * 3, sw, 10000, 140000, density, true);
  contrastSlider = new Slider("Contrast", sx, sy + gap * 4, sw, 0.3, 3.0, contrast, false);
  radialBiasSlider = new Slider("Radial bias", sx, sy + gap * 5, sw, 0.2, 3.0, radialBias, false);
}

void draw() {
  background(0);

  updateParametersFromSliders();
  drawPattern();
  drawFrame(plateCX, plateCY, plateRadius);
  drawPanel();
  drawUI();
}

void drawPattern() {
  fill(255);

  for (int i = 0; i < density; i++) {
    float a = random(TWO_PI);
    float r = sqrt(random(1)) * plateRadius;

    float dx = cos(a) * r;
    float dy = sin(a) * r;

    float px = plateCX + dx;
    float py = plateCY + dy;

    // Local coordinates inside the circle
    float u = (dx / plateRadius + 1.0) * 0.5;
    float v = (dy / plateRadius + 1.0) * 0.5;

    // Zoom relative to the center of the pattern
    float zoomedU = (u - 0.5) / patternZoom + 0.5;
    float zoomedV = (v - 0.5) / patternZoom + 0.5;

    // Navigate through the pattern itself
    float sampleU = zoomedU + patternOffsetX;
    float sampleV = zoomedV + patternOffsetY;

    float value = chladni(sampleU, sampleV, mFreq, nFreq);

    float probability = exp(-abs(value) / thickness);
    probability = pow(probability, contrast);

    // Probability from the center
    float radial = r / plateRadius;
    float radialWeight = pow(1.0 - radial, radialBias);
    probability *= radialWeight;

    if (random(1) < probability) {
      square(px, py, squareSize);
    }
  }
}

float chladni(float x, float y, float m, float n) {
  return sin(PI * m * x) * sin(PI * n * y)
       - sin(PI * n * x) * sin(PI * m * y);
}

void drawFrame(float cx, float cy, float r) {
  noFill();
  stroke(panningPattern ? 140 : 50);
  strokeWeight(1.2);
  circle(cx, cy, r * 2.0);
  noStroke();
  strokeWeight(1);
}

void drawPanel() {
  noStroke();
  fill(18);
  rect(width - uiWidth, 0, uiWidth, height);

  stroke(45);
  line(width - uiWidth, 0, width - uiWidth, height);
  noStroke();
}

void updateParametersFromSliders() {
  mFreq = mSlider.getValue();
  nFreq = nSlider.getValue();
  thickness = thicknessSlider.getValue();
  density = int(densitySlider.getValue());
  contrast = contrastSlider.getValue();
  radialBias = radialBiasSlider.getValue();
}

void drawUI() {
  float panelX = width - uiWidth + 20;

  fill(255);
  textAlign(LEFT, TOP);
  textSize(18);
  text("Chladni Controls", panelX, 20);

  fill(180);
  textSize(12);
  text("Drag inside the circle to pan\nUse mouse wheel to zoom\nPress R to reset view", panelX, 48);

  mSlider.draw();
  nSlider.draw();
  thicknessSlider.draw();
  densitySlider.draw();
  contrastSlider.draw();
  radialBiasSlider.draw();

  fill(180);
  textSize(12);
  textAlign(LEFT, TOP);
  text(
    "m = " + nf(mFreq, 1, 2) + "\n" +
    "n = " + nf(nFreq, 1, 2) + "\n" +
    "thickness = " + nf(thickness, 1, 3) + "\n" +
    "density = " + density + "\n" +
    "contrast = " + nf(contrast, 1, 2) + "\n" +
    "radial = " + nf(radialBias, 1, 2) + "\n" +
    "offset x = " + nf(patternOffsetX, 1, 3) + "\n" +
    "offset y = " + nf(patternOffsetY, 1, 3) + "\n" +
    "zoom = " + nf(patternZoom, 1, 2),
    panelX,
    height - 160
  );
}

void mousePressed() {
  activeSlider = null;

  if (mSlider.hit(mouseX, mouseY)) activeSlider = mSlider;
  else if (nSlider.hit(mouseX, mouseY)) activeSlider = nSlider;
  else if (thicknessSlider.hit(mouseX, mouseY)) activeSlider = thicknessSlider;
  else if (densitySlider.hit(mouseX, mouseY)) activeSlider = densitySlider;
  else if (contrastSlider.hit(mouseX, mouseY)) activeSlider = contrastSlider;
  else if (radialBiasSlider.hit(mouseX, mouseY)) activeSlider = radialBiasSlider;

  if (activeSlider != null) {
    activeSlider.update(mouseX);
    return;
  }

  if (dist(mouseX, mouseY, plateCX, plateCY) <= plateRadius) {
    panningPattern = true;
    lastMouseX = mouseX;
    lastMouseY = mouseY;
  }
}

void mouseDragged() {
  if (activeSlider != null) {
    activeSlider.update(mouseX);
    return;
  }

  if (panningPattern) {
    float dx = mouseX - lastMouseX;
    float dy = mouseY - lastMouseY;

    float zoomAdjustedPan = panScale / patternZoom;
    patternOffsetX -= (dx / plateDiameter) * zoomAdjustedPan;
    patternOffsetY -= (dy / plateDiameter) * zoomAdjustedPan;

    lastMouseX = mouseX;
    lastMouseY = mouseY;
  }
}

void mouseReleased() {
  activeSlider = null;
  panningPattern = false;
}

void mouseWheel(processing.event.MouseEvent event) {
  if (dist(mouseX, mouseY, plateCX, plateCY) > plateRadius) return;

  float e = event.getCount();
  float zoomFactor = 1.0 - e * 0.08;
  float newZoom = constrain(patternZoom * zoomFactor, minZoom, maxZoom);

  // Keep the point under the mouse stable while zooming
  float dx = mouseX - plateCX;
  float dy = mouseY - plateCY;

  float u = (dx / plateRadius + 1.0) * 0.5;
  float v = (dy / plateRadius + 1.0) * 0.5;

  float oldSampleU = (u - 0.5) / patternZoom + 0.5 + patternOffsetX;
  float oldSampleV = (v - 0.5) / patternZoom + 0.5 + patternOffsetY;

  patternZoom = newZoom;

  patternOffsetX = oldSampleU - ((u - 0.5) / patternZoom + 0.5);
  patternOffsetY = oldSampleV - ((v - 0.5) / patternZoom + 0.5);
}

void keyPressed() {
  if (key == 'r' || key == 'R') {
    patternOffsetX = 0.0;
    patternOffsetY = 0.0;
    patternZoom = 1.0;
  }
}

class Slider {
  String label;
  float x, y, w;
  float minVal, maxVal;
  float value;
  boolean snapInt;

  Slider(String label, float x, float y, float w, float minVal, float maxVal, float value, boolean snapInt) {
    this.label = label;
    this.x = x;
    this.y = y;
    this.w = w;
    this.minVal = minVal;
    this.maxVal = maxVal;
    this.value = value;
    this.snapInt = snapInt;
  }

  void draw() {
    fill(230);
    textAlign(LEFT, CENTER);
    textSize(13);
    text(label, x, y - 18);

    stroke(90);
    line(x, y, x + w, y);

    float knobX = map(value, minVal, maxVal, x, x + w);

    noStroke();
    fill(255);
    circle(knobX, y, 16);
  }

  boolean hit(float mx, float my) {
    float knobX = map(value, minVal, maxVal, x, x + w);
    return dist(mx, my, knobX, y) < 14 || (mx >= x && mx <= x + w && abs(my - y) < 12);
  }

  void update(float mx) {
    float clampedX = constrain(mx, x, x + w);
    float raw = map(clampedX, x, x + w, minVal, maxVal);

    if (snapInt) value = round(raw);
    else value = raw;
  }

  float getValue() {
    return value;
  }
}
