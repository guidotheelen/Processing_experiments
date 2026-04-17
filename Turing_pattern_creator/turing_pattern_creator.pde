// Turing Pattern Creator (Gray-Scott)
// Built for exploring many different pattern families.

int VIEW_W = 860;
int VIEW_H = 900;
int PANEL_W = 340;

int W = VIEW_W;
int H = VIEW_H;

float[][] a, b, nextA, nextB;

float diffA = 1.0;
float diffB = 0.50;
float feed = 0.037;
float kill = 0.065;
float seedSize = 34;
float speckleDensity = 0.020;
int stepsPerFrame = 10;

boolean paused = false;
boolean invert = false;

String[] presetNames = {
  "Mitosis Dots",
  "Worm Trails",
  "Maze Stripes",
  "Coral Growth",
  "Bubble Cells",
  "Chaotic Mix"
};

// diffA, diffB, feed, kill, seedSize, speed, seedMode
float[][] presetValues = {
  {1.00, 0.50, 0.037, 0.065, 32, 10, 0},
  {1.00, 0.47, 0.078, 0.061, 20, 12, 3},
  {1.00, 0.52, 0.029, 0.057, 30, 9, 2},
  {1.00, 0.48, 0.054, 0.062, 22, 11, 1},
  {1.00, 0.42, 0.022, 0.051, 36, 8, 0},
  {1.00, 0.55, 0.046, 0.066, 26, 14, 4}
};

String[] seedModeNames = {
  "Center Blob",
  "Twin Blobs",
  "Ring",
  "Stripes",
  "Speckles",
  "Cross"
};

int currentPreset = 0;
int seedMode = 0;

Button presetPrevBtn, presetNextBtn, presetApplyBtn;
Button seedPrevBtn, seedNextBtn;
Button applyBtn, randomParamsBtn, randomSeedBtn, randomAllBtn;
Button pauseBtn, invertBtn, saveBtn;

Slider diffASlider, diffBSlider, feedSlider, killSlider;
Slider seedSizeSlider, speckleSlider, speedSlider;

void settings() {
  pixelDensity(1);
  size(VIEW_W + PANEL_W, VIEW_H);
}

void setup() {
  surface.setTitle("Turing Pattern Creator - Multi Style");
  textSize(14);
  initUI();
  applyPreset(0);
  applyParameters();
}

void initUI() {
  int x = VIEW_W + 20;
  int w = PANEL_W - 40;

  presetPrevBtn = new Button(x, 58, 42, 28, "<");
  presetNextBtn = new Button(x + w - 42, 58, 42, 28, ">");
  presetApplyBtn = new Button(x + 50, 58, w - 100, 28, "Load Preset");

  seedPrevBtn = new Button(x, 118, 42, 28, "<");
  seedNextBtn = new Button(x + w - 42, 118, 42, 28, ">");

  diffASlider = new Slider(x, 188, w, 14, 0.70, 1.30, diffA);
  diffBSlider = new Slider(x, 238, w, 14, 0.10, 0.70, diffB);
  feedSlider = new Slider(x, 288, w, 14, 0.005, 0.100, feed);
  killSlider = new Slider(x, 338, w, 14, 0.020, 0.090, kill);
  seedSizeSlider = new Slider(x, 388, w, 14, 6, 120, seedSize);
  speckleSlider = new Slider(x, 438, w, 14, 0.001, 0.100, speckleDensity);
  speedSlider = new Slider(x, 488, w, 14, 1, 50, stepsPerFrame);

  applyBtn = new Button(x, 540, w, 30, "Apply");
  randomParamsBtn = new Button(x, 578, w, 30, "Random Params");
  randomSeedBtn = new Button(x, 616, w, 30, "Random Seed");
  randomAllBtn = new Button(x, 654, w, 30, "Random All");

  pauseBtn = new Button(x, 704, w, 30, "Pause");
  invertBtn = new Button(x, 742, w, 30, "Invert: Off");
  saveBtn = new Button(x, 780, w, 30, "Save");
}

void applyPreset(int idx) {
  currentPreset = (idx + presetNames.length) % presetNames.length;

  float[] p = presetValues[currentPreset];
  diffA = p[0];
  diffB = p[1];
  feed = p[2];
  kill = p[3];
  seedSize = p[4];
  stepsPerFrame = int(p[5]);
  seedMode = int(p[6]);

  diffASlider.value = diffA;
  diffBSlider.value = diffB;
  feedSlider.value = feed;
  killSlider.value = kill;
  seedSizeSlider.value = seedSize;
  speedSlider.value = stepsPerFrame;
}

void applyParameters() {
  diffA = diffASlider.value;
  diffB = diffBSlider.value;
  feed = feedSlider.value;
  kill = killSlider.value;
  seedSize = seedSizeSlider.value;
  speckleDensity = speckleSlider.value;
  stepsPerFrame = int(speedSlider.value);

  resetField();
  seedField();

  paused = false;
  pauseBtn.label = "Pause";
}

void randomizeParameters() {
  diffASlider.value = random(diffASlider.min, diffASlider.max);
  diffBSlider.value = random(diffBSlider.min, diffBSlider.max);
  feedSlider.value = random(feedSlider.min, feedSlider.max);
  killSlider.value = random(killSlider.min, killSlider.max);
  seedSizeSlider.value = random(seedSizeSlider.min, seedSizeSlider.max);
  speedSlider.value = random(speedSlider.min, speedSlider.max);
}

void randomizeSeedMode() {
  seedMode = int(random(seedModeNames.length));
  seedSizeSlider.value = random(seedSizeSlider.min, seedSizeSlider.max);
  speckleSlider.value = random(speckleSlider.min, speckleSlider.max);
}

void randomizeAll() {
  currentPreset = int(random(presetNames.length));
  applyPreset(currentPreset);
  randomizeParameters();
  randomizeSeedMode();
  applyParameters();
}

void resetField() {
  a = new float[W][H];
  b = new float[W][H];
  nextA = new float[W][H];
  nextB = new float[W][H];

  for (int x = 0; x < W; x++) {
    for (int y = 0; y < H; y++) {
      a[x][y] = 1;
      b[x][y] = 0;
    }
  }
}

void seedField() {
  int cx = W / 2;
  int cy = H / 2;
  int r = max(2, int(seedSize));

  if (seedMode == 0) {
    stampRect(cx - r, cy - r, 2 * r, 2 * r, 1);
  } else if (seedMode == 1) {
    stampCircle(int(W * 0.35), cy, r, 1);
    stampCircle(int(W * 0.65), cy, r, 1);
  } else if (seedMode == 2) {
    int outer = r;
    int inner = max(2, int(r * 0.65));
    stampRing(cx, cy, inner, outer, 1);
  } else if (seedMode == 3) {
    int stripeCount = 6;
    int stripeW = max(2, int(r * 0.55));
    for (int i = 0; i < stripeCount; i++) {
      float t = map(i, 0, stripeCount - 1, 0.2, 0.8);
      int sx = int(W * t) - stripeW / 2;
      stampRect(sx, cy - r, stripeW, 2 * r, 1);
    }
  } else if (seedMode == 4) {
    int n = int(W * H * speckleDensity);
    for (int i = 0; i < n; i++) {
      int x = int(random(W));
      int y = int(random(H));
      b[x][y] = 1;
      a[x][y] = 0;
    }
  } else if (seedMode == 5) {
    int arm = max(8, int(r * 1.4));
    stampRect(cx - arm, cy - int(r * 0.35), 2 * arm, int(r * 0.7), 1);
    stampRect(cx - int(r * 0.35), cy - arm, int(r * 0.7), 2 * arm, 1);
  }
}

void stampRect(int x0, int y0, int w, int h, float amount) {
  int x1 = constrain(x0, 0, W);
  int y1 = constrain(y0, 0, H);
  int x2 = constrain(x0 + w, 0, W);
  int y2 = constrain(y0 + h, 0, H);

  for (int x = x1; x < x2; x++) {
    for (int y = y1; y < y2; y++) {
      b[x][y] = amount;
      a[x][y] = 1.0 - amount;
    }
  }
}

void stampCircle(int cx, int cy, int r, float amount) {
  int x1 = max(0, cx - r);
  int y1 = max(0, cy - r);
  int x2 = min(W, cx + r);
  int y2 = min(H, cy + r);

  float rr = r * r;
  for (int x = x1; x < x2; x++) {
    for (int y = y1; y < y2; y++) {
      float dx = x - cx;
      float dy = y - cy;
      if (dx * dx + dy * dy <= rr) {
        b[x][y] = amount;
        a[x][y] = 1.0 - amount;
      }
    }
  }
}

void stampRing(int cx, int cy, int innerR, int outerR, float amount) {
  int x1 = max(0, cx - outerR);
  int y1 = max(0, cy - outerR);
  int x2 = min(W, cx + outerR);
  int y2 = min(H, cy + outerR);

  float inSq = innerR * innerR;
  float outSq = outerR * outerR;

  for (int x = x1; x < x2; x++) {
    for (int y = y1; y < y2; y++) {
      float dx = x - cx;
      float dy = y - cy;
      float d2 = dx * dx + dy * dy;
      if (d2 >= inSq && d2 <= outSq) {
        b[x][y] = amount;
        a[x][y] = 1.0 - amount;
      }
    }
  }
}

void draw() {
  background(0);

  stepsPerFrame = int(speedSlider.value);
  if (!paused) {
    for (int i = 0; i < stepsPerFrame; i++) {
      stepSimulation();
    }
  }

  drawField();
  drawUI();
}

void stepSimulation() {
  for (int x = 1; x < W - 1; x++) {
    for (int y = 1; y < H - 1; y++) {
      float A = a[x][y];
      float B = b[x][y];

      float lapA = laplace(a, x, y);
      float lapB = laplace(b, x, y);
      float reaction = A * B * B;

      nextA[x][y] = constrain(
        A + (diffA * lapA - reaction + feed * (1 - A)),
        0,
        1
      );

      nextB[x][y] = constrain(
        B + (diffB * lapB + reaction - (kill + feed) * B),
        0,
        1
      );
    }
  }

  float[][] t = a;
  a = nextA;
  nextA = t;

  t = b;
  b = nextB;
  nextB = t;
}

float laplace(float[][] g, int x, int y) {
  float sum = 0;
  sum += g[x][y] * -1.0;
  sum += g[x - 1][y] * 0.2;
  sum += g[x + 1][y] * 0.2;
  sum += g[x][y - 1] * 0.2;
  sum += g[x][y + 1] * 0.2;
  sum += g[x - 1][y - 1] * 0.05;
  sum += g[x + 1][y - 1] * 0.05;
  sum += g[x - 1][y + 1] * 0.05;
  sum += g[x + 1][y + 1] * 0.05;
  return sum;
}

void drawField() {
  loadPixels();
  for (int y = 0; y < H; y++) {
    int row = y * width;
    for (int x = 0; x < W; x++) {
      float v = constrain(a[x][y] - b[x][y], 0, 1);
      if (invert) v = 1.0 - v;
      pixels[row + x] = color(v * 255);
    }
  }
  updatePixels();
}

void drawUI() {
  int x = VIEW_W;
  int ox = x + 20;

  fill(28);
  rect(x, 0, PANEL_W, height);

  fill(255);
  textAlign(LEFT, BASELINE);

  text("Preset: " + presetNames[currentPreset], ox, 44);
  presetPrevBtn.draw();
  presetApplyBtn.draw();
  presetNextBtn.draw();

  text("Seed: " + seedModeNames[seedMode], ox, 104);
  seedPrevBtn.draw();
  seedNextBtn.draw();

  text("Diff A: " + nf(diffASlider.value, 1, 3), ox, 180);
  diffASlider.draw();
  text("Diff B: " + nf(diffBSlider.value, 1, 3), ox, 230);
  diffBSlider.draw();
  text("Feed: " + nf(feedSlider.value, 1, 3), ox, 280);
  feedSlider.draw();
  text("Kill: " + nf(killSlider.value, 1, 3), ox, 330);
  killSlider.draw();
  text("Seed Size: " + int(seedSizeSlider.value), ox, 380);
  seedSizeSlider.draw();
  text("Speckle Density: " + nf(speckleSlider.value, 1, 3), ox, 430);
  speckleSlider.draw();
  text("Speed: " + int(speedSlider.value), ox, 480);
  speedSlider.draw();

  applyBtn.draw();
  randomParamsBtn.draw();
  randomSeedBtn.draw();
  randomAllBtn.draw();
  pauseBtn.draw();
  invertBtn.draw();
  saveBtn.draw();

  fill(180);
  text("Shortcuts: [space] pause, [r] random all, [s] save", ox, 840);
}

void mousePressed() {
  if (diffASlider.handlePress(mouseX, mouseY)) return;
  if (diffBSlider.handlePress(mouseX, mouseY)) return;
  if (feedSlider.handlePress(mouseX, mouseY)) return;
  if (killSlider.handlePress(mouseX, mouseY)) return;
  if (seedSizeSlider.handlePress(mouseX, mouseY)) return;
  if (speckleSlider.handlePress(mouseX, mouseY)) return;
  if (speedSlider.handlePress(mouseX, mouseY)) return;

  if (presetPrevBtn.hit(mouseX, mouseY)) {
    applyPreset(currentPreset - 1);
    applyParameters();
  }

  if (presetNextBtn.hit(mouseX, mouseY)) {
    applyPreset(currentPreset + 1);
    applyParameters();
  }

  if (presetApplyBtn.hit(mouseX, mouseY)) {
    applyPreset(currentPreset);
    applyParameters();
  }

  if (seedPrevBtn.hit(mouseX, mouseY)) {
    seedMode = (seedMode - 1 + seedModeNames.length) % seedModeNames.length;
    applyParameters();
  }

  if (seedNextBtn.hit(mouseX, mouseY)) {
    seedMode = (seedMode + 1) % seedModeNames.length;
    applyParameters();
  }

  if (applyBtn.hit(mouseX, mouseY)) {
    applyParameters();
  }

  if (randomParamsBtn.hit(mouseX, mouseY)) {
    randomizeParameters();
    applyParameters();
  }

  if (randomSeedBtn.hit(mouseX, mouseY)) {
    randomizeSeedMode();
    applyParameters();
  }

  if (randomAllBtn.hit(mouseX, mouseY)) {
    randomizeAll();
  }

  if (pauseBtn.hit(mouseX, mouseY)) {
    paused = !paused;
    pauseBtn.label = paused ? "Resume" : "Pause";
  }

  if (invertBtn.hit(mouseX, mouseY)) {
    invert = !invert;
    invertBtn.label = invert ? "Invert: On" : "Invert: Off";
  }

  if (saveBtn.hit(mouseX, mouseY)) {
    saveFrame("pattern-####.png");
  }
}

void mouseDragged() {
  diffASlider.handleDrag(mouseX);
  diffBSlider.handleDrag(mouseX);
  feedSlider.handleDrag(mouseX);
  killSlider.handleDrag(mouseX);
  seedSizeSlider.handleDrag(mouseX);
  speckleSlider.handleDrag(mouseX);
  speedSlider.handleDrag(mouseX);
}

void mouseReleased() {
  diffASlider.dragging = false;
  diffBSlider.dragging = false;
  feedSlider.dragging = false;
  killSlider.dragging = false;
  seedSizeSlider.dragging = false;
  speckleSlider.dragging = false;
  speedSlider.dragging = false;
}

void keyPressed() {
  if (key == ' ') {
    paused = !paused;
    pauseBtn.label = paused ? "Resume" : "Pause";
  } else if (key == 'r' || key == 'R') {
    randomizeAll();
  } else if (key == 's' || key == 'S') {
    saveFrame("pattern-####.png");
  }
}

class Button {
  float x, y, w, h;
  String label;

  Button(float x, float y, float w, float h, String l) {
    this.x = x;
    this.y = y;
    this.w = w;
    this.h = h;
    label = l;
  }

  void draw() {
    fill(80);
    rect(x, y, w, h, 4);
    fill(255);
    textAlign(CENTER, CENTER);
    text(label, x + w / 2, y + h / 2);
  }

  boolean hit(float mx, float my) {
    return mx > x && mx < x + w && my > y && my < y + h;
  }
}

class Slider {
  float x, y, w, h;
  float min, max, value;
  boolean dragging = false;

  Slider(float x, float y, float w, float h, float min, float max, float v) {
    this.x = x;
    this.y = y;
    this.w = w;
    this.h = h;
    this.min = min;
    this.max = max;
    value = v;
  }

  void draw() {
    fill(70);
    rect(x, y, w, h, 3);

    float t = (value - min) / (max - min);
    float k = x + t * w;

    fill(180);
    rect(x, y, k - x, h, 3);

    fill(255);
    ellipse(k, y + h / 2, 11, 11);
  }

  boolean handlePress(float mx, float my) {
    if (mx > x && mx < x + w && my > y - 6 && my < y + h + 6) {
      dragging = true;
      update(mx);
      return true;
    }
    return false;
  }

  void handleDrag(float mx) {
    if (dragging) update(mx);
  }

  void update(float mx) {
    float t = constrain((mx - x) / w, 0, 1);
    value = lerp(min, max, t);
  }
}
