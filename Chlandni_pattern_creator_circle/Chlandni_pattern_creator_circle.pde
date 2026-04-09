int squareSize = 1;
int screen_width = 700;
int screen_height = 860;

float plateDiameter;
float plateRadius;

// Chladni parameters
float mFreq = 4.0;
float nFreq = 7.0;
float thickness = 0.020;
int density = 90000;
float contrast = 1.0;

// Optional radial bias: higher = stronger emphasis from center outward
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

  plateDiameter = min(screen_width, screen_height - 180) * 0.82;
  plateRadius = plateDiameter * 0.5;

  float sx = 160;
  float sw = 400;
  float sy = 715;
  float gap = 28;

  mSlider = new Slider("M frequency", sx, sy + gap * 0, sw, 0.5, 12.0, mFreq, false);
  nSlider = new Slider("N frequency", sx, sy + gap * 1, sw, 0.5, 12.0, nFreq, false);
  thicknessSlider = new Slider("Thickness", sx, sy + gap * 2, sw, 0.003, 0.060, thickness, false);
  densitySlider = new Slider("Density", sx, sy + gap * 3, sw, 10000, 140000, density, true);
  contrastSlider = new Slider("Contrast", sx, sy + gap * 4, sw, 0.3, 3.0, contrast, false);
  radialBiasSlider = new Slider("Radial bias", sx, sy + gap * 5, sw, 0.2, 3.0, radialBias, false);

  textFont(createFont("Arial", 14));
}

void draw() {
  background(0);

  updateParametersFromSliders();

  float cx = width * 0.5;
  float cy = 28 + plateRadius;

  fill(255);

  for (int i = 0; i < density; i++) {
    // Uniform random point in a disk
    float a = random(TWO_PI);
    float r = sqrt(random(1)) * plateRadius;

    float dx = cos(a) * r;
    float dy = sin(a) * r;

    float px = cx + dx;
    float py = cy + dy;

    // Map circle-centered coords to normalized domain [0..1]
    float u = (dx / plateRadius + 1.0) * 0.5;
    float v = (dy / plateRadius + 1.0) * 0.5;

    float value = chladni(u, v, mFreq, nFreq);

    // Base probability from nodal closeness
    float probability = exp(-abs(value) / thickness);
    probability = pow(probability, contrast);

    // Radial weighting: probability referenced from center
    // radial = 0 at center, 1 at rim
    float radial = r / plateRadius;
    float radialWeight = pow(1.0 - radial, radialBias);

    probability *= radialWeight;

    if (random(1) < probability) {
      square(px, py, squareSize);
    }
  }

  drawFrame(cx, cy, plateRadius);
  drawUI();
}

float chladni(float x, float y, float m, float n) {
  return sin(PI * m * x) * sin(PI * n * y)
       - sin(PI * n * x) * sin(PI * m * y);
}

void drawFrame(float cx, float cy, float r) {
  noFill();
  stroke(45);
  circle(cx, cy, r * 2.0);
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
  fill(255);
  textAlign(LEFT, CENTER);
  textSize(14);
  text("Chladni Playground (circular probability field)", 24, 695);

  mSlider.draw();
  nSlider.draw();
  thicknessSlider.draw();
  densitySlider.draw();
  contrastSlider.draw();
  radialBiasSlider.draw();

  fill(180);
  textAlign(CENTER, CENTER);
  text(
    "m=" + nf(mFreq, 1, 2) +
    "   n=" + nf(nFreq, 1, 2) +
    "   radial=" + nf(radialBias, 1, 2),
    width / 2,
    height - 12
  );
}

void mousePressed() {
  if (mSlider.hit(mouseX, mouseY)) activeSlider = mSlider;
  else if (nSlider.hit(mouseX, mouseY)) activeSlider = nSlider;
  else if (thicknessSlider.hit(mouseX, mouseY)) activeSlider = thicknessSlider;
  else if (densitySlider.hit(mouseX, mouseY)) activeSlider = densitySlider;
  else if (contrastSlider.hit(mouseX, mouseY)) activeSlider = contrastSlider;
  else if (radialBiasSlider.hit(mouseX, mouseY)) activeSlider = radialBiasSlider;

  if (activeSlider != null) activeSlider.update(mouseX);
}

void mouseDragged() {
  if (activeSlider != null) activeSlider.update(mouseX);
}

void mouseReleased() {
  activeSlider = null;
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
    text(label, 24, y);

    stroke(90);
    line(x, y, x + w, y);

    float knobX = map(value, minVal, maxVal, x, x + w);

    noStroke();
    fill(255);
    circle(knobX, y, 18);

    fill(200);
    textAlign(LEFT, CENTER);
    if (snapInt) {
      text(str(int(value)), x + w + 18, y);
    } else {
      text(nf(value, 1, 2), x + w + 18, y);
    }
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
