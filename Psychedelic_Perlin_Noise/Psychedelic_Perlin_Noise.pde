/*
  Psychedelic_Perlin_Noise.pde
  ----------------------------
  Animated psychedelic texture made from layered 3D Perlin noise.

  Controls:
  - Space: pause/resume animation
  - R: reseed noise pattern
  - Up/Down: increase/decrease spatial detail
  - Left/Right: decrease/increase animation speed
*/

float noiseScale = 0.0010;
float timeScale = 0.002;
float renderScale = 0.62;

boolean paused = false;
int overlayFrames = 120;
int targetFps = 120;

PImage lowResBuffer;

void setup() {
  size(1600, 900);
  pixelDensity(1);
  colorMode(HSB, 360, 100, 100);
  frameRate(targetFps);
  smooth(8);
  noiseDetail(6, 0.50);
  lowResBuffer = createImage(max(1, (int) (width * renderScale)), max(1, (int) (height * renderScale)), RGB);
}

void draw() {
  float t = frameCount * timeScale;
  float noiseScaleAtRender = noiseScale / renderScale;
  int rw = lowResBuffer.width;
  int rh = lowResBuffer.height;
  int halfW = (rw + 1) / 2;
  int halfH = (rh + 1) / 2;

  float hueDrift = frameCount * 0.55;
  float t032 = t * 0.32;
  float t024 = t * 0.24;
  float t015 = t * 0.15;
  float t020 = t * 0.20;
  float t029 = t * 0.29;
  float t013 = t * 0.13;
  float t072 = t * 0.72;
  float t050 = t * 0.50;
  float t085 = t * 0.85;
  float t150 = t * 1.50;
  float t160 = t * 1.60;
  float t420 = t * 4.20;

  lowResBuffer.loadPixels();

  // Performance path: compute only one quadrant, then mirror into four.
  for (int y = 0; y < halfH; y++) {
    int yMirror = rh - 1 - y;
    int rowTop = y * rw;
    int rowBottom = yMirror * rw;
    float py = y * noiseScaleAtRender;

    for (int x = 0; x < halfW; x++) {
      int xMirror = rw - 1 - x;
      float px = x * noiseScaleAtRender;

      float warpA = noise(px * 0.90 + t032, py * 0.85 - t024, t015);
      float warpB = noise(px * 1.15 - t020 + 41.2, py * 1.10 + t029 + 20.8, -t013);
      float fx = px + (warpA - 0.5) * 1.45;
      float fy = py + (warpB - 0.5) * 1.45;

      // Two-layer domain-warped noise keeps curves flowing without strobing.
      float nA = noise(fx + t072, fy + t050, t020);
      float nB = noise(fx * 1.70 + 31.7, fy * 1.55 + 88.3, -t015);

      float field = nA * 0.70 + nB * 0.30;
      float contour = abs(sin((field * 18.0 + t085) * PI));
      float lineMask = smoothStep(0.30, 0.02, contour);
      float haloMask = smoothStep(0.70, 0.12, contour);

      float swirl = sin((nA * 1.8 + nB * 1.4) * TWO_PI + t150);
      float bands = sin(field * TWO_PI * 3.9 + t160);
      float pulse = 0.5 + 0.5 * sin(t420 + nB * TWO_PI);

      float hueValue =
        field * 240.0 +
        swirl * 64.0 +
        bands * 28.0 +
        lineMask * 96.0 +
        hueDrift;

      float saturation =
        78.0 +
        8.0 * abs(bands) +
        14.0 * haloMask +
        12.0 * lineMask;
      saturation = constrain(saturation, 0, 100);

      float brightness =
        15.0 +
        18.0 * abs(swirl) +
        16.0 * pulse +
        27.0 * haloMask +
        58.0 * lineMask;
      brightness = constrain(brightness, 0, 100);

      int pixelColor = color((hueValue % 360 + 360) % 360, saturation, brightness);
      lowResBuffer.pixels[rowTop + x] = pixelColor;
      lowResBuffer.pixels[rowTop + xMirror] = pixelColor;
      lowResBuffer.pixels[rowBottom + x] = pixelColor;
      lowResBuffer.pixels[rowBottom + xMirror] = pixelColor;
    }
  }

  lowResBuffer.updatePixels();
  image(lowResBuffer, 0, 0, width, height);
  drawOverlay();
}

float smoothStep(float edge0, float edge1, float x) {
  float t = constrain((x - edge0) / (edge1 - edge0), 0, 1);
  return t * t * (3.0 - 2.0 * t);
}

void drawOverlay() {
  if (overlayFrames <= 0) {
    return;
  }

  fill(0, 0, 100, 82);
  rect(14, 14, 480, 88, 10);

  fill(0, 0, 18);
  textSize(14);
  text(
    "Space pause | R reseed | Up/Down detail (" + nf(noiseScale, 1, 4) + ") | Left/Right speed (" + nf(timeScale, 1, 4) + ")",
    24,
    40
  );
  text(
    "Render scale [ / ] (" + nf(renderScale, 1, 2) + ") | FPS " + nf(frameRate, 2, 1),
    24,
    62
  );
  text("Psychedelic Perlin Noise", 24, 84);

  overlayFrames--;
}

void keyPressed() {
  if (key == ' ') {
    paused = !paused;
    if (paused) {
      noLoop();
    } else {
      loop();
    }
    overlayFrames = 120;
  } else if (key == 'r' || key == 'R') {
    noiseSeed((int) random(1, 1000000));
    redraw();
    overlayFrames = 120;
  } else if (keyCode == UP) {
    noiseScale = min(0.02, noiseScale * 1.12);
    redraw();
    overlayFrames = 120;
  } else if (keyCode == DOWN) {
    noiseScale = max(0.0018, noiseScale / 1.12);
    redraw();
    overlayFrames = 120;
  } else if (keyCode == RIGHT) {
    timeScale = min(0.08, timeScale * 1.1);
    redraw();
    overlayFrames = 120;
  } else if (keyCode == LEFT) {
    timeScale = max(0.001, timeScale / 1.1);
    redraw();
    overlayFrames = 120;
  } else if (key == '[') {
    renderScale = max(0.34, renderScale - 0.04);
    rebuildBuffer();
    redraw();
    overlayFrames = 120;
  } else if (key == ']') {
    renderScale = min(1.0, renderScale + 0.04);
    rebuildBuffer();
    redraw();
    overlayFrames = 120;
  }
}

void rebuildBuffer() {
  lowResBuffer = createImage(max(1, (int) (width * renderScale)), max(1, (int) (height * renderScale)), RGB);
}
