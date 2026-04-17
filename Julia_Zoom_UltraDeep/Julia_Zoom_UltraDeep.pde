/*
  Julia_Zoom_UltraDeep.pde
  ------------------------
  Ultra-deep widescreen Julia-set zoom renderer.

  What this sketch does:
  1) Renders a Julia set for a fixed parameter k.
  2) Performs a long automated zoom toward a chosen target point.
  3) Saves one PNG per frame.

  After rendering, build a video with ffmpeg (example):
    ffmpeg -framerate 30 -i ultradeep-frame-%07d.png -c:v libx264 -pix_fmt yuv420p julia_ultradeep.mp4

  Notes:
  - Rendering deep zooms is CPU-heavy.
  - This preset is intentionally heavy.
  - Reduce TOTAL_FRAMES / finalZoom / maxIterations if it is too slow.
*/

// ------------------------------------------------------------
// Video/export settings
// ------------------------------------------------------------
int RENDER_WIDTH = 1920;   // 16:9 widescreen (Full HD)
int RENDER_HEIGHT = 1080;
int FPS = 30;
int TOTAL_FRAMES = 5400;   // 180 seconds at 30 fps (3 minutes)
boolean SAVE_FRAMES = true;
String FRAME_PATTERN = "ultradeep-frame-#######.png";

// ------------------------------------------------------------
// Julia parameter k = kReal + i * kImag
// Try changing this for very different worlds.
// ------------------------------------------------------------
double kReal = -0.8;
double kImag = 0.156;

// ------------------------------------------------------------
// Camera path
// ------------------------------------------------------------
// Start center can be broad/central.
double startCenterReal = 0.0;
double startCenterImag = 0.0;

// Target center = "cool point" we zoom into.
// This point works well for k = -0.8 + 0.156i.
double targetCenterReal = -0.1715;
double targetCenterImag = 0.6520;

// Initial visible height in the imaginary axis.
double startImagHeight = 3.2;

// How much total magnification by the final frame.
// Larger values = deeper zoom, but harder to keep detailed.
double finalZoom = 5.0e10;

// ------------------------------------------------------------
// Quality controls
// ------------------------------------------------------------
int baseIterations = 260;
int maxIterations = 12000;
double iterationGrowthPerOctave = 38.0;

// Optional text overlay for debug/progress.
boolean SHOW_HUD = false;

int frameIndex = 0;

void settings() {
  size(RENDER_WIDTH, RENDER_HEIGHT);
  pixelDensity(1);
}

void setup() {
  frameRate(FPS);
  colorMode(HSB, 360, 100, 100);
  surface.setTitle("Julia Zoom Ultra-Deep Renderer");
}

void draw() {
  if (frameIndex >= TOTAL_FRAMES) {
    println("Done. Rendered " + TOTAL_FRAMES + " frames.");
    noLoop();
    return;
  }

  renderZoomFrame(frameIndex);

  if (SAVE_FRAMES) {
    // In Processing, # placeholders create numbered filenames.
    saveFrame(FRAME_PATTERN);
  }

  if (frameIndex % 60 == 0) {
    println("Rendered frame " + frameIndex + " / " + (TOTAL_FRAMES - 1));
  }

  frameIndex++;
}

void renderZoomFrame(int i) {
  double t = i / (double) Math.max(1, TOTAL_FRAMES - 1);  // 0..1

  /*
    Use easing so zoom starts gentle and builds intensity.
    Linear t can feel mechanically constant.
  */
  double easedZoomT = easeInOutQuint(t);
  double easedDriftT = easeInOutCubic(t);

  // Drift center from start -> target over time.
  double centerReal = lerpDouble(startCenterReal, targetCenterReal, easedDriftT);
  double centerImag = lerpDouble(startCenterImag, targetCenterImag, easedDriftT);

  // Exponential zoom gives steady multiplicative scale change.
  double zoom = Math.pow(finalZoom, easedZoomT);

  // Keep aspect ratio correct for widescreen.
  double imagHeight = startImagHeight / zoom;
  double realWidth = imagHeight * (width / (double) height);

  double minReal = centerReal - 0.5 * realWidth;
  double maxReal = centerReal + 0.5 * realWidth;
  double minImag = centerImag - 0.5 * imagHeight;
  double maxImag = centerImag + 0.5 * imagHeight;

  // Increase iterations with zoom depth so details remain sharp.
  int iterationLimit = adaptiveIterationCount(zoom);

  loadPixels();
  for (int y = 0; y < height; y++) {
    double cImag = mapToRange(y, 0, height - 1, minImag, maxImag);

    for (int x = 0; x < width; x++) {
      double cReal = mapToRange(x, 0, width - 1, minReal, maxReal);

      // Julia: z starts at pixel coordinate, constant k is fixed.
      double zReal = cReal;
      double zImag = cImag;

      int iteration = 0;
      while (iteration < iterationLimit && (zReal * zReal + zImag * zImag) <= 4.0) {
        double oldReal = zReal;
        double oldImag = zImag;

        zReal = oldReal * oldReal - oldImag * oldImag + kReal;
        zImag = 2.0 * oldReal * oldImag + kImag;
        iteration++;
      }

      int pixelColor = colorForEscape(iteration, zReal, zImag, iterationLimit);
      pixels[x + y * width] = pixelColor;
    }
  }
  updatePixels();

  if (SHOW_HUD) {
    drawHud(i, zoom, iterationLimit, centerReal, centerImag);
  }
}

int adaptiveIterationCount(double zoom) {
  // Log2(zoom) is a simple proxy for zoom depth.
  double zoomDepth = Math.log(Math.max(1.0, zoom)) / Math.log(2.0);
  int adaptive = baseIterations + (int) (zoomDepth * iterationGrowthPerOctave);
  return constrain(adaptive, baseIterations, maxIterations);
}

int colorForEscape(int iteration, double zReal, double zImag, int iterationLimit) {
  // Likely inside Julia set.
  if (iteration == iterationLimit) {
    return color(0, 0, 0);
  }

  /*
    Smooth escape-time coloring:
      nu = n + 1 - log(log(|z|))/log(2)
    Reduces visible color banding.
  */
  double magnitudeSq = zReal * zReal + zImag * zImag;
  double nu = iteration + 1.0 - Math.log(Math.log(Math.sqrt(magnitudeSq))) / Math.log(2.0);

  float t = (float) (nu / Math.max(1, iterationLimit));
  t = constrain(t, 0, 1);

  // "Cinematic" gradient palette.
  float hue = (205.0 + 280.0 * t) % 360.0;
  float saturation = map(t, 0, 1, 72, 98);
  float brightness = map(pow(t, 0.55), 0, 1, 10, 100);
  return color(hue, saturation, brightness);
}

void drawHud(int i, double zoom, int iterationLimit, double centerReal, double centerImag) {
  noStroke();
  fill(0, 0, 100, 88);
  rect(14, 14, 430, 92, 10);

  fill(210, 90, 25);
  textSize(14);
  text("Frame: " + i + " / " + (TOTAL_FRAMES - 1), 24, 40);
  text("Zoom: " + nf((float) zoom, 1, 2) + "x", 24, 62);
  text("Iterations: " + iterationLimit, 24, 84);
  text("Center: " + nf((float) centerReal, 1, 6) + ", " + nf((float) centerImag, 1, 6), 160, 84);
}

// ----------------------------
// Small math helpers
// ----------------------------
double mapToRange(double value, double inMin, double inMax, double outMin, double outMax) {
  double t = (value - inMin) / (inMax - inMin);
  return outMin + t * (outMax - outMin);
}

double lerpDouble(double a, double b, double t) {
  return a + (b - a) * t;
}

double easeInOutQuad(double t) {
  if (t < 0.5) {
    return 2.0 * t * t;
  }
  return 1.0 - Math.pow(-2.0 * t + 2.0, 2.0) / 2.0;
}

double easeInOutCubic(double t) {
  if (t < 0.5) {
    return 4.0 * t * t * t;
  }
  return 1.0 - Math.pow(-2.0 * t + 2.0, 3.0) / 2.0;
}

double easeInOutQuint(double t) {
  if (t < 0.5) {
    return 16.0 * t * t * t * t * t;
  }
  return 1.0 - Math.pow(-2.0 * t + 2.0, 5.0) / 2.0;
}
