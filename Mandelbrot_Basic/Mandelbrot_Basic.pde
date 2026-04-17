/*
  Mandelbrot_Basic.pde
  --------------------
  This sketch draws a very basic Mandelbrot fractal and now supports
  slow zooming toward the cursor position with color.

  Big idea:
  The Mandelbrot set is built from the equation:

      z(n + 1) = z(n)^2 + c

  where:
  - z is a complex number (has a real and imaginary part)
  - c is also a complex number
  - we start every test with z = 0

  For each pixel on the screen:
  1) We map that pixel to a complex number c.
  2) We repeatedly apply z = z^2 + c.
  3) If z grows too large (its magnitude exceeds 2), we say it "escapes".
  4) If it does not escape after many iterations, we treat it as inside
     (or very close to) the Mandelbrot set.

  Why this creates a picture:
  - Each pixel gets a different c.
  - Different c values escape at different speeds.
  - We color based on the escape speed.
*/

// Full-quality iteration count (used when view is still).
// Higher values show more detail but run slower.
int maxIterations = 140;

// While zoom is moving, we render a faster preview so interaction feels fluid.
// As soon as movement stops, we render full quality again.
int previewIterations = 70;
int previewSampleStep = 2;

// The area of the complex plane we want to see.
// These ranges are chosen to show the classic full Mandelbrot shape.
double minReal = -2.5;
double maxReal = 1.0;
double minImag = -1.5;
double maxImag = 1.5;

/*
  Smooth zoom state
  -----------------
  Instead of queueing fixed step counts, we use zoom velocity + damping:
  - mouse wheel adds zoom impulse
  - each frame applies that motion
  - motion decays smoothly over time

  Why this feels better:
  - movement is smooth
  - wheel input blends naturally
  - the zoom direction is anchored to the cursor
*/
double zoomAnchorReal = 0.0;
double zoomAnchorImag = 0.0;
boolean zoomPaused = false;
double zoomVelocity = 0.0;
double zoomImpulse = 0.045;
double zoomDamping = 0.86;
double zoomStopThreshold = 0.0008;

// Drag-to-pan state.
boolean isDragging = false;
boolean dragMoved = false;
int lastDragX = 0;
int lastDragY = 0;

void settings() {
  // In Processing on HiDPI/Retina screens, one sketch "pixel" can map to
  // multiple hardware pixels.
  // If we manually write the pixels[] array using x + y * width indexing,
  // that mismatch can cause duplicated/partial rendering.
  //
  // For this beginner sketch, we force density to 1 so:
  // - pixels[] length is exactly width * height
  // - index math stays simple and predictable
  size(800, 800);
  pixelDensity(1);
}

void setup() {
  // Size is now defined in settings() (required when using pixelDensity).

  // We switch to HSB so we can control hue/saturation/brightness directly.
  // That makes fractal coloring easier to reason about than raw RGB.
  colorMode(HSB, 360, 100, 100);

  // Draw the first frame once, then stop until interaction happens.
  renderMandelbrot(maxIterations, 1);
  noLoop();
}

void draw() {
  /*
    Draw strategy:
    - paused => one clean full-quality render, then stop
    - moving => apply zoom momentum + fast preview render
    - idle   => one final full-quality render, then stop
  */
  if (zoomPaused) {
    renderMandelbrot(maxIterations, 1);
    noLoop();
    return;
  }

  if (Math.abs(zoomVelocity) > zoomStopThreshold) {
    double zoomFactor = Math.exp(-zoomVelocity);
    applyZoomFactor(zoomFactor);
    zoomVelocity *= zoomDamping;
    renderMandelbrot(previewIterations, previewSampleStep);
  } else {
    zoomVelocity = 0.0;
    renderMandelbrot(maxIterations, 1);
    noLoop();
  }
}

void renderMandelbrot(int iterationLimit, int sampleStep) {
  // We calculate every pixel manually and then draw once.
  // Using loadPixels/updatePixels is faster than drawing many points.
  loadPixels();

  /*
    sampleStep lets us trade detail for speed:
    - sampleStep = 1 => full resolution
    - sampleStep = 2 => 2x2 blocks (faster preview while moving)
  */
  for (int y = 0; y < height; y += sampleStep) {
    for (int x = 0; x < width; x += sampleStep) {

      // Map screen coordinates to a complex number c = (cReal + cImag * i).
      // x maps to the real axis, y maps to the imaginary axis.
      double cReal = pixelToReal(x);
      double cImag = pixelToImag(y);

      // z starts at 0 + 0i for each pixel.
      double zReal = 0.0;
      double zImag = 0.0;

      // Count how many iterations happen before escape.
      int iteration = 0;

      // Repeat z = z^2 + c while:
      // 1) we have not reached the current iteration limit
      // 2) |z|^2 <= 4 (equivalent to |z| <= 2)
      while (iteration < iterationLimit && (zReal * zReal + zImag * zImag) <= 4.0) {

        // Save current z parts because both new equations depend on old values.
        double oldReal = zReal;
        double oldImag = zImag;

        // Complex square:
        // (a + bi)^2 = (a^2 - b^2) + (2ab)i
        // Then add c.
        zReal = oldReal * oldReal - oldImag * oldImag + cReal;
        zImag = 2.0 * oldReal * oldImag + cImag;

        iteration++;
      }

      // Choose a color:
      // - likely inside set -> black
      // - escaped values -> smooth gradient
      int pixelColor = colorForIteration(iteration, zReal, zImag, iterationLimit);
      paintBlock(x, y, sampleStep, pixelColor);
    }
  }

  // Push modified pixel array to the screen.
  updatePixels();
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
  // Points that did not escape are likely inside the Mandelbrot set.
  if (iteration == iterationLimit) {
    return color(0, 0, 0);
  }

  /*
    Smooth coloring
    ---------------
    Raw iteration counts produce visible "bands".
    This smooth estimate gives a fractional iteration value:

      smooth = n + 1 - log(log(|z|)) / log(2)

    That creates more fluid gradients between bands.
  */
  double magnitudeSq = zReal * zReal + zImag * zImag;
  double smoothIteration =
    iteration + 1.0 - Math.log(Math.log(Math.sqrt(magnitudeSq))) / Math.log(2.0);

  float t = (float) (smoothIteration / max(1, iterationLimit));
  t = constrain(t, 0, 1);

  // Color design:
  // - hue cycles through a cool-to-warm range
  // - saturation increases slightly with t
  // - brightness follows sqrt(t) for stronger edge glow
  float hue = (210.0 + 260.0 * t) % 360.0;
  float saturation = map(t, 0, 1, 70, 95);
  float brightness = map(sqrt(t), 0, 1, 18, 100);

  return color(hue, saturation, brightness);
}

double pixelToReal(int x) {
  // Convert pixel x to [0..1], then scale to [minReal..maxReal].
  double t = x / (double) (width - 1);
  return minReal + t * (maxReal - minReal);
}

double pixelToImag(int y) {
  // Convert pixel y to [0..1], then scale to [minImag..maxImag].
  double t = y / (double) (height - 1);
  return minImag + t * (maxImag - minImag);
}

void applyZoomFactor(double factor) {
  /*
    Zoom around the anchor point with this formula:

      newBound = anchor + (oldBound - anchor) * factor

    With factor < 1:
    - every bound moves closer to the anchor
    - the view window shrinks
    - we zoom in smoothly toward the anchor
  */
  minReal = zoomAnchorReal + (minReal - zoomAnchorReal) * factor;
  maxReal = zoomAnchorReal + (maxReal - zoomAnchorReal) * factor;
  minImag = zoomAnchorImag + (minImag - zoomAnchorImag) * factor;
  maxImag = zoomAnchorImag + (maxImag - zoomAnchorImag) * factor;
}

void panByPixels(int dx, int dy) {
  /*
    Convert mouse movement in screen pixels to movement in complex-plane units.
    We use the current scale of the visible window:

      realPerPixel = (maxReal - minReal) / (width - 1)
      imagPerPixel = (maxImag - minImag) / (height - 1)

    Drag direction is inverted to feel like "grabbing" the fractal:
    dragging right moves the image right, so the complex window shifts left.
  */
  double realPerPixel = (maxReal - minReal) / (double) (width - 1);
  double imagPerPixel = (maxImag - minImag) / (double) (height - 1);

  double shiftReal = -dx * realPerPixel;
  double shiftImag = -dy * imagPerPixel;

  minReal += shiftReal;
  maxReal += shiftReal;
  minImag += shiftImag;
  maxImag += shiftImag;
}

void mouseWheel(processing.event.MouseEvent event) {
  /*
    Mouse wheel behavior:
    - wheel up   -> zoom in slowly toward cursor
    - wheel down -> zoom out slowly away from cursor (inverse factor)
  */
  int direction = event.getCount();
  if (direction == 0) {
    return;
  }

  // If user was paused and starts scrolling again, auto-resume.
  zoomPaused = false;

  // Complex coordinate currently under the mouse cursor.
  zoomAnchorReal = pixelToReal(mouseX);
  zoomAnchorImag = pixelToImag(mouseY);

  /*
    Wheel direction:
    - direction < 0 (wheel up): zoom in  -> positive velocity
    - direction > 0 (wheel down): zoom out -> negative velocity
  */
  zoomVelocity += (-direction) * zoomImpulse;

  // Clamp velocity so zoom never gets too jumpy.
  zoomVelocity = constrain((float) zoomVelocity, -0.22, 0.22);

  // Start draw() loop so animation can run.
  loop();
}

void mousePressed() {
  if (mouseButton != LEFT) {
    return;
  }

  isDragging = true;
  dragMoved = false;
  lastDragX = mouseX;
  lastDragY = mouseY;

  // Stop zoom momentum while user is actively dragging.
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
  dragMoved = true;
  lastDragX = mouseX;
  lastDragY = mouseY;

  // Preview quality while dragging for smoother interaction.
  renderMandelbrot(previewIterations, previewSampleStep);
}

void mouseReleased() {
  if (!isDragging) {
    return;
  }

  isDragging = false;

  // After drag ends, redraw at full quality.
  if (dragMoved) {
    renderMandelbrot(maxIterations, 1);
  }
}

void keyPressed() {
  // Space toggles pause/resume for the zoom animation.
  if (key != ' ') {
    return;
  }

  zoomPaused = !zoomPaused;

  // Re-render immediately so the paused frame is always clean and current.
  renderMandelbrot(maxIterations, 1);

  if (zoomPaused) {
    noLoop();
  } else if (Math.abs(zoomVelocity) > zoomStopThreshold) {
    loop();
  }
}
