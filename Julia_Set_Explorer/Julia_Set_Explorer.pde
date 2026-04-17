/*
  Julia_Set_Explorer.pde
  ----------------------
  Another fractal in a separate file: a Julia set explorer.

  Formula:
    z(n + 1) = z(n)^2 + k

  Difference from Mandelbrot:
  - Mandelbrot: c changes per pixel, z starts at 0.
  - Julia set: k is fixed, z starts at the pixel coordinate.

  Controls:
  - Mouse wheel: smooth zoom toward cursor
  - Left drag: pan
  - Space: pause/resume zoom animation
  - R: reset view
  - 1..4: switch Julia presets
  - M: toggle "mouse controls k"
*/

// ----------------------------
// Complex-plane view window
// ----------------------------
double startMinReal = -1.9;
double startMaxReal = 1.9;
double startMinImag = -1.9;
double startMaxImag = 1.9;

double minReal = startMinReal;
double maxReal = startMaxReal;
double minImag = startMinImag;
double maxImag = startMaxImag;

// ----------------------------
// Julia parameter k = (kReal + i*kImag)
// ----------------------------
double kReal = -0.8;
double kImag = 0.156;
boolean mouseControlsK = false;

// ----------------------------
// Render quality
// ----------------------------
int maxIterations = 170;
int pausedIterations = 300;
int previewIterations = 90;
int previewSampleStep = 2;

// ----------------------------
// Smooth zoom motion
// ----------------------------
double zoomAnchorReal = 0.0;
double zoomAnchorImag = 0.0;
double zoomVelocity = 0.0;
double zoomImpulse = 0.045;
double zoomDamping = 0.86;
double zoomStopThreshold = 0.0008;
boolean zoomPaused = false;

// ----------------------------
// Drag-to-pan state
// ----------------------------
boolean isDragging = false;
int lastDragX = 0;
int lastDragY = 0;

void settings() {
  size(800, 800);
  pixelDensity(1);
}

void setup() {
  colorMode(HSB, 360, 100, 100);
  renderJulia(maxIterations, 1);
  noLoop();
}

void draw() {
  if (mouseControlsK) {
    // Map cursor position to a common interesting Julia parameter range.
    kReal = map(mouseX, 0, width, -1.2, 1.2);
    kImag = map(mouseY, 0, height, -1.2, 1.2);
  }

  if (zoomPaused) {
    renderJulia(pausedIterations, 1);
    noLoop();
    return;
  }

  if (Math.abs(zoomVelocity) > zoomStopThreshold) {
    double zoomFactor = Math.exp(-zoomVelocity);
    applyZoomFactor(zoomFactor);
    zoomVelocity *= zoomDamping;
    renderJulia(previewIterations, previewSampleStep);
  } else if (mouseControlsK) {
    // If k follows mouse, keep updating at full quality.
    renderJulia(maxIterations, 1);
  } else {
    zoomVelocity = 0.0;
    renderJulia(maxIterations, 1);
    noLoop();
  }
}

void renderJulia(int iterationLimit, int sampleStep) {
  loadPixels();

  for (int y = 0; y < height; y += sampleStep) {
    for (int x = 0; x < width; x += sampleStep) {
      // For Julia sets, z starts at the pixel coordinate.
      double zReal = pixelToReal(x);
      double zImag = pixelToImag(y);
      int iteration = 0;

      while (iteration < iterationLimit && (zReal * zReal + zImag * zImag) <= 4.0) {
        double oldReal = zReal;
        double oldImag = zImag;

        zReal = oldReal * oldReal - oldImag * oldImag + kReal;
        zImag = 2.0 * oldReal * oldImag + kImag;
        iteration++;
      }

      int pixelColor = colorForIteration(iteration, zReal, zImag, iterationLimit);
      paintBlock(x, y, sampleStep, pixelColor);
    }
  }

  updatePixels();
  drawOverlay();
}

void paintBlock(int x0, int y0, int sizeStep, int pixelColor) {
  int yEnd = min(y0 + sizeStep, height);
  int xEnd = min(x0 + sizeStep, width);

  for (int yy = y0; yy < yEnd; yy++) {
    int rowStart = yy * width;
    for (int xx = x0; xx < xEnd; xx++) {
      pixels[rowStart + xx] = pixelColor;
    }
  }
}

int colorForIteration(int iteration, double zReal, double zImag, int iterationLimit) {
  if (iteration == iterationLimit) {
    return color(0, 0, 0);
  }

  // Smooth coloring for continuous gradients.
  double magnitudeSq = zReal * zReal + zImag * zImag;
  double smoothIteration =
    iteration + 1.0 - Math.log(Math.log(Math.sqrt(magnitudeSq))) / Math.log(2.0);

  float t = (float) (smoothIteration / max(1, iterationLimit));
  t = constrain(t, 0, 1);

  float hue = (180.0 + 220.0 * t) % 360.0;
  float saturation = map(t, 0, 1, 70, 98);
  float brightness = map(sqrt(t), 0, 1, 12, 100);
  return color(hue, saturation, brightness);
}

void drawOverlay() {
  fill(0, 0, 100, 85);
  rect(12, 12, 300, 62, 8);

  fill(220, 85, 22);
  textSize(13);
  text("Julia k = " + nf((float)kReal, 1, 4) + "  +  " + nf((float)kImag, 1, 4) + "i", 20, 34);

  fill(0, 0, 20);
  text("1..4 presets | M mouse-k | Space pause | R reset", 20, 56);
}

double pixelToReal(int x) {
  double t = x / (double) (width - 1);
  return minReal + t * (maxReal - minReal);
}

double pixelToImag(int y) {
  double t = y / (double) (height - 1);
  return minImag + t * (maxImag - minImag);
}

void applyZoomFactor(double factor) {
  minReal = zoomAnchorReal + (minReal - zoomAnchorReal) * factor;
  maxReal = zoomAnchorReal + (maxReal - zoomAnchorReal) * factor;
  minImag = zoomAnchorImag + (minImag - zoomAnchorImag) * factor;
  maxImag = zoomAnchorImag + (maxImag - zoomAnchorImag) * factor;
}

void panByPixels(int dx, int dy) {
  double realPerPixel = (maxReal - minReal) / (double) (width - 1);
  double imagPerPixel = (maxImag - minImag) / (double) (height - 1);

  minReal += -dx * realPerPixel;
  maxReal += -dx * realPerPixel;
  minImag += -dy * imagPerPixel;
  maxImag += -dy * imagPerPixel;
}

void resetView() {
  minReal = startMinReal;
  maxReal = startMaxReal;
  minImag = startMinImag;
  maxImag = startMaxImag;
  zoomVelocity = 0.0;
  zoomPaused = false;
}

void setPreset(int id) {
  if (id == 1) {
    kReal = -0.8;
    kImag = 0.156;
  } else if (id == 2) {
    kReal = 0.285;
    kImag = 0.01;
  } else if (id == 3) {
    kReal = -0.4;
    kImag = 0.6;
  } else if (id == 4) {
    kReal = -0.70176;
    kImag = -0.3842;
  }
}

void mouseWheel(processing.event.MouseEvent event) {
  int direction = event.getCount();
  if (direction == 0) {
    return;
  }

  zoomPaused = false;
  zoomAnchorReal = pixelToReal(mouseX);
  zoomAnchorImag = pixelToImag(mouseY);
  zoomVelocity += (-direction) * zoomImpulse;
  zoomVelocity = constrain((float) zoomVelocity, -0.22, 0.22);
  loop();
}

void mousePressed() {
  if (mouseButton != LEFT) {
    return;
  }

  isDragging = true;
  lastDragX = mouseX;
  lastDragY = mouseY;
  zoomVelocity = 0.0;
}

void mouseDragged() {
  if (!isDragging) {
    return;
  }

  int dx = mouseX - lastDragX;
  int dy = mouseY - lastDragY;
  if (dx == 0 && dy == 0) {
    return;
  }

  panByPixels(dx, dy);
  lastDragX = mouseX;
  lastDragY = mouseY;

  if (zoomPaused) {
    renderJulia(pausedIterations, 1);
  } else {
    renderJulia(previewIterations, previewSampleStep);
  }
}

void mouseReleased() {
  if (!isDragging) {
    return;
  }

  isDragging = false;
  if (zoomPaused) {
    renderJulia(pausedIterations, 1);
  } else {
    renderJulia(maxIterations, 1);
  }
}

void keyPressed() {
  if (key == ' ') {
    zoomPaused = !zoomPaused;
    renderJulia(zoomPaused ? pausedIterations : maxIterations, 1);

    if (zoomPaused) {
      noLoop();
    } else if (Math.abs(zoomVelocity) > zoomStopThreshold || mouseControlsK) {
      loop();
    }
    return;
  }

  if (key == 'r' || key == 'R') {
    resetView();
    renderJulia(maxIterations, 1);
    noLoop();
    return;
  }

  if (key == 'm' || key == 'M') {
    mouseControlsK = !mouseControlsK;
    if (mouseControlsK) {
      loop();
    } else if (Math.abs(zoomVelocity) <= zoomStopThreshold && !zoomPaused) {
      renderJulia(maxIterations, 1);
      noLoop();
    }
    return;
  }

  if (key >= '1' && key <= '4') {
    setPreset(key - '0');
    renderJulia(zoomPaused ? pausedIterations : maxIterations, 1);
    if (mouseControlsK) {
      // Preset selection implies manual k for now.
      mouseControlsK = false;
      if (Math.abs(zoomVelocity) <= zoomStopThreshold && !zoomPaused) {
        noLoop();
      }
    }
  }
}
