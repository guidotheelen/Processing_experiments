// Simple High-Resolution Turing Pattern (Gray-Scott)
// Inverted color output
// Seed via text input (no slider)

int VIEW_W = 900;
int VIEW_H = 900;
int PANEL_W = 220;

int W = VIEW_W;
int H = VIEW_H;

float[][] a, b, nextA, nextB;

int seed = 1234;
float diffA, diffB, feed, kill;
int stepsPerFrame = 8;
boolean paused = false;

Button applyBtn, randomBtn, saveBtn, pauseBtn;
Slider speedSlider;
TextInput seedInput;

void settings() {
  pixelDensity(1);
  size(VIEW_W + PANEL_W, VIEW_H);
}

void setup() {
  surface.setTitle("Simple Turing Pattern");
  textSize(14);
  initUI();
  applySeed(seed);
}

void initUI() {
  int x = VIEW_W + 20;

  seedInput = new TextInput(x, 60, PANEL_W - 40, 24, str(seed));
  speedSlider = new Slider(x, 120, PANEL_W - 40, 16, 1, 40, stepsPerFrame);

  applyBtn = new Button(x, 160, PANEL_W - 40, 30, "Apply");
  randomBtn = new Button(x, 200, PANEL_W - 40, 30, "Random");
  saveBtn = new Button(x, 240, PANEL_W - 40, 30, "Save");
  pauseBtn = new Button(x, 280, PANEL_W - 40, 30, "Pause");
}

void applySeed(int s) {
  seed = constrain(s, 1, 999999);
  seedInput.text = str(seed);
  randomSeed(seed);

  diffA = 1.0;
  diffB = 0.30 + random(0.20);
  feed  = 0.020 + random(0.050);
  kill  = 0.045 + random(0.020);

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

  int r = 24 + int(random(18));
  int cx = W / 2;
  int cy = H / 2;

  for (int x = cx - r; x < cx + r; x++) {
    for (int y = cy - r; y < cy + r; y++) {
      b[x][y] = 1;
      a[x][y] = 0;
    }
  }

  paused = false;
  pauseBtn.label = "Pause";
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

  float[][] t;
  t = a;
  a = nextA;
  nextA = t;

  t = b;
  b = nextB;
  nextB = t;
}

float laplace(float[][] g, int x, int y) {
  float sum = 0;
  sum += g[x][y] * -1;
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
      float inverted = 1.0 - v;
      pixels[row + x] = color(inverted * 255);
    }
  }
  updatePixels();
}

void drawUI() {
  int x = VIEW_W;
  fill(28);
  rect(x, 0, PANEL_W, height);

  fill(255);
  text("Seed:", x + 20, 40);
  seedInput.draw();

  text("Speed: " + int(speedSlider.value), x + 20, 100);
  speedSlider.draw();

  applyBtn.draw();
  randomBtn.draw();
  saveBtn.draw();
  pauseBtn.draw();
}

void mousePressed() {
  if (seedInput.handlePress(mouseX, mouseY)) return;
  if (speedSlider.handlePress(mouseX, mouseY)) return;

  if (applyBtn.hit(mouseX, mouseY)) {
    applySeed(seedInput.getInt());
  }

  if (randomBtn.hit(mouseX, mouseY)) {
    applySeed(int(random(1, 999999)));
  }

  if (saveBtn.hit(mouseX, mouseY)) {
    saveFrame("pattern-####.png");
  }

  if (pauseBtn.hit(mouseX, mouseY)) {
    paused = !paused;
    pauseBtn.label = paused ? "Resume" : "Pause";
  }
}

void keyPressed() {
  seedInput.handleKey(key, keyCode);
}

void mouseDragged() {
  speedSlider.handleDrag(mouseX);
}

void mouseReleased() {
  speedSlider.dragging = false;
}

class TextInput {
  float x, y, w, h;
  String text;
  boolean active = false;

  TextInput(float x, float y, float w, float h, String t) {
    this.x = x;
    this.y = y;
    this.w = w;
    this.h = h;
    text = t;
  }

  void draw() {
    fill(active ? 80 : 60);
    rect(x, y, w, h);
    fill(255);
    textAlign(LEFT, CENTER);
    text(text, x + 6, y + h / 2);
  }

  boolean handlePress(float mx, float my) {
    active = (mx > x && mx < x + w && my > y && my < y + h);
    return active;
  }

  void handleKey(char k, int code) {
    if (!active) return;

    if (k == '\n' || k == '\r') return;

    if (code == BACKSPACE && text.length() > 0) {
      text = text.substring(0, text.length() - 1);
    } else if (k >= '0' && k <= '9') {
      text += k;
    }
  }

  int getInt() {
    try {
      return int(text);
    } catch (Exception e) {
      return 1;
    }
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
    rect(x, y, w, h);
    fill(255);
    textAlign(CENTER, CENTER);
    text(label, x + w / 2, y + h / 2);
  }

  boolean hit(float mx, float my) {
    return mx > x && mx < x + w && my > y && my < y + h;
  }
}

class Slider {
  float x, y, w, h, min, max, value;
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
    rect(x, y, w, h);
    float t = (value - min) / (max - min);
    float k = x + t * w;
    fill(190);
    rect(x, y, k - x, h);
    fill(255);
    ellipse(k, y + h / 2, 12, 12);
  }

  boolean handlePress(float mx, float my) {
    if (mx > x && mx < x + w && my > y - 5 && my < y + h + 5) {
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
