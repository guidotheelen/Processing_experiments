/*
  Turing_pattern_creator_widescreen.pde
  -------------------------------------
  Widescreen Gray-Scott reaction-diffusion explorer.

  Main requirement:
  - Press SPACE to generate a completely new pattern.

  Extra keys:
  - P: pause/resume simulation
  - S: save current frame as PNG
  - H: show/hide HUD text

  Mouse:
  - Click/drag to inject chemical B (draw into the pattern).
*/

int W = 1280;
int H = 720;

float[] a, b, nextA, nextB;

float diffA = 1.0;
float diffB = 0.50;
float feed = 0.037;
float kill = 0.065;
int stepsPerFrame = 10;

int seedMode = 0;
int paletteMode = 0;
int patternId = 0;

boolean paused = false;
boolean showHUD = true;

void settings() {
  size(W, H);
  pixelDensity(1);
}

void setup() {
  colorMode(HSB, 360, 100, 100);
  textSize(14);
  surface.setTitle("Turing Pattern Creator - Widescreen");

  int n = W * H;
  a = new float[n];
  b = new float[n];
  nextA = new float[n];
  nextB = new float[n];

  generateNewPattern();
}

void draw() {
  if (!paused) {
    for (int i = 0; i < stepsPerFrame; i++) {
      stepSimulation();
    }
  }

  drawField();

  if (showHUD) {
    drawHUD();
  }
}

void generateNewPattern() {
  patternId++;
  randomSeed((int) random(1, 999999));

  // Randomized Gray-Scott parameters from ranges known to produce patterns.
  diffA = 1.0;
  diffB = random(0.30, 0.68);
  feed = random(0.010, 0.090);
  kill = random(0.035, 0.078);
  stepsPerFrame = (int) random(6, 20);

  seedMode = (int) random(6);
  paletteMode = (int) random(4);

  resetField();
  seedField(seedMode);
  paused = false;
}

void resetField() {
  int n = W * H;
  for (int i = 0; i < n; i++) {
    a[i] = 1.0;
    b[i] = 0.0;
    nextA[i] = 1.0;
    nextB[i] = 0.0;
  }
}

void seedField(int mode) {
  int cx = W / 2;
  int cy = H / 2;
  int base = (int) random(24, 72);

  if (mode == 0) {
    stampRect(cx - base, cy - base, 2 * base, 2 * base, 1.0);
  } else if (mode == 1) {
    stampCircle((int)(W * 0.33), cy, base, 1.0);
    stampCircle((int)(W * 0.67), cy, base, 1.0);
  } else if (mode == 2) {
    int outer = base;
    int inner = max(8, (int)(base * 0.65));
    stampRing(cx, cy, inner, outer, 1.0);
  } else if (mode == 3) {
    int stripeCount = 7;
    int stripeW = max(4, (int)(base * 0.45));
    for (int i = 0; i < stripeCount; i++) {
      float t = map(i, 0, stripeCount - 1, 0.15, 0.85);
      int sx = (int)(W * t) - stripeW / 2;
      stampRect(sx, cy - base, stripeW, 2 * base, 1.0);
    }
  } else if (mode == 4) {
    int n = (int)(W * H * random(0.002, 0.020));
    for (int i = 0; i < n; i++) {
      int x = (int) random(W);
      int y = (int) random(H);
      setCell(x, y, 1.0);
    }
  } else if (mode == 5) {
    int arm = (int)(base * 1.4);
    stampRect(cx - arm, cy - (int)(base * 0.28), 2 * arm, (int)(base * 0.56), 1.0);
    stampRect(cx - (int)(base * 0.28), cy - arm, (int)(base * 0.56), 2 * arm, 1.0);
  }
}

void stampRect(int x0, int y0, int rw, int rh, float amount) {
  int x1 = constrain(x0, 0, W);
  int y1 = constrain(y0, 0, H);
  int x2 = constrain(x0 + rw, 0, W);
  int y2 = constrain(y0 + rh, 0, H);

  for (int y = y1; y < y2; y++) {
    int row = y * W;
    for (int x = x1; x < x2; x++) {
      int idx = row + x;
      b[idx] = amount;
      a[idx] = 1.0 - amount;
    }
  }
}

void stampCircle(int cx, int cy, int r, float amount) {
  int x1 = max(0, cx - r);
  int y1 = max(0, cy - r);
  int x2 = min(W, cx + r);
  int y2 = min(H, cy + r);
  float rr = r * r;

  for (int y = y1; y < y2; y++) {
    int row = y * W;
    for (int x = x1; x < x2; x++) {
      float dx = x - cx;
      float dy = y - cy;
      if (dx * dx + dy * dy <= rr) {
        int idx = row + x;
        b[idx] = amount;
        a[idx] = 1.0 - amount;
      }
    }
  }
}

void stampRing(int cx, int cy, int innerR, int outerR, float amount) {
  int x1 = max(0, cx - outerR);
  int y1 = max(0, cy - outerR);
  int x2 = min(W, cx + outerR);
  int y2 = min(H, cy + outerR);
  float in2 = innerR * innerR;
  float out2 = outerR * outerR;

  for (int y = y1; y < y2; y++) {
    int row = y * W;
    for (int x = x1; x < x2; x++) {
      float dx = x - cx;
      float dy = y - cy;
      float d2 = dx * dx + dy * dy;
      if (d2 >= in2 && d2 <= out2) {
        int idx = row + x;
        b[idx] = amount;
        a[idx] = 1.0 - amount;
      }
    }
  }
}

void setCell(int x, int y, float amount) {
  if (x < 0 || x >= W || y < 0 || y >= H) return;
  int idx = x + y * W;
  b[idx] = amount;
  a[idx] = 1.0 - amount;
}

void injectBrush(int cx, int cy, int r, float amount) {
  int x1 = max(0, cx - r);
  int y1 = max(0, cy - r);
  int x2 = min(W, cx + r);
  int y2 = min(H, cy + r);
  float rr = r * r;

  for (int y = y1; y < y2; y++) {
    int row = y * W;
    for (int x = x1; x < x2; x++) {
      float dx = x - cx;
      float dy = y - cy;
      if (dx * dx + dy * dy <= rr) {
        int idx = row + x;
        b[idx] = max(b[idx], amount);
        a[idx] = 1.0 - b[idx];
      }
    }
  }
}

void stepSimulation() {
  for (int y = 1; y < H - 1; y++) {
    for (int x = 1; x < W - 1; x++) {
      int idx = x + y * W;
      float A = a[idx];
      float B = b[idx];

      float lapA = laplace(a, x, y);
      float lapB = laplace(b, x, y);
      float reaction = A * B * B;

      nextA[idx] = constrain(
        A + (diffA * lapA - reaction + feed * (1.0 - A)),
        0.0,
        1.0
      );
      nextB[idx] = constrain(
        B + (diffB * lapB + reaction - (kill + feed) * B),
        0.0,
        1.0
      );
    }
  }

  // Keep borders stable.
  for (int x = 0; x < W; x++) {
    int top = x;
    int bottom = x + (H - 1) * W;
    nextA[top] = 1.0;
    nextB[top] = 0.0;
    nextA[bottom] = 1.0;
    nextB[bottom] = 0.0;
  }
  for (int y = 0; y < H; y++) {
    int left = y * W;
    int right = left + (W - 1);
    nextA[left] = 1.0;
    nextB[left] = 0.0;
    nextA[right] = 1.0;
    nextB[right] = 0.0;
  }

  float[] t;
  t = a; a = nextA; nextA = t;
  t = b; b = nextB; nextB = t;
}

float laplace(float[] g, int x, int y) {
  int i = x + y * W;
  float sum = 0.0;
  sum += g[i] * -1.0;
  sum += g[i - 1] * 0.2;
  sum += g[i + 1] * 0.2;
  sum += g[i - W] * 0.2;
  sum += g[i + W] * 0.2;
  sum += g[i - W - 1] * 0.05;
  sum += g[i - W + 1] * 0.05;
  sum += g[i + W - 1] * 0.05;
  sum += g[i + W + 1] * 0.05;
  return sum;
}

void drawField() {
  loadPixels();

  int n = W * H;
  for (int i = 0; i < n; i++) {
    float v = constrain(a[i] - b[i], 0.0, 1.0);
    float bb = b[i];
    pixels[i] = paletteColor(v, bb);
  }

  updatePixels();
}

int paletteColor(float v, float bVal) {
  if (paletteMode == 0) {
    float hue = (205.0 + 140.0 * (1.0 - v)) % 360.0;
    float sat = map(bVal, 0, 1, 55, 95);
    float bri = map(v, 0, 1, 10, 100);
    return color(hue, sat, bri);
  } else if (paletteMode == 1) {
    float hue = (20.0 + 85.0 * (1.0 - v)) % 360.0;
    float sat = map(v, 0, 1, 85, 45);
    float bri = map(v, 0, 1, 6, 100);
    return color(hue, sat, bri);
  } else if (paletteMode == 2) {
    float hue = (300.0 + 110.0 * bVal) % 360.0;
    float sat = map(v, 0, 1, 62, 98);
    float bri = map(v, 0, 1, 8, 100);
    return color(hue, sat, bri);
  } else {
    // High-contrast monochrome.
    float g = pow(v, 0.8) * 100.0;
    return color(0, 0, g);
  }
}

void drawHUD() {
  noStroke();
  fill(0, 0, 100, 86);
  rect(14, 12, 760, 74, 10);

  fill(220, 90, 24);
  text(
    "Pattern " + patternId +
    " | feed " + nf(feed, 1, 4) +
    " | kill " + nf(kill, 1, 4) +
    " | diffB " + nf(diffB, 1, 3) +
    " | steps " + stepsPerFrame +
    " | seed " + seedMode +
    " | palette " + paletteMode,
    26, 38
  );

  fill(0, 0, 22);
  text("SPACE new pattern | P pause | S save | H hud | mouse draw", 26, 62);
}

void mousePressed() {
  injectBrush(mouseX, mouseY, 16, 1.0);
}

void mouseDragged() {
  injectBrush(mouseX, mouseY, 16, 1.0);
}

void keyPressed() {
  if (key == ' ') {
    generateNewPattern();
    return;
  }

  if (key == 'p' || key == 'P') {
    paused = !paused;
    return;
  }

  if (key == 's' || key == 'S') {
    saveFrame("turing-wide-#######.png");
    return;
  }

  if (key == 'h' || key == 'H') {
    showHUD = !showHUD;
    return;
  }
}
