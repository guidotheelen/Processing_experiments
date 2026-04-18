import processing.event.MouseEvent;

/*
  Lorenz_Attractor_Creator.pde
  ----------------------------
  Interactive Lorenz attractor explorer.

  Mouse:
  - Left drag: orbit camera
  - Right drag: pan
  - Wheel: zoom

  Keys:
  - Space: pause/resume simulation
  - C: clear trail
  - R: reset simulation + camera
  - T: toggle auto-rotation
  - G: toggle axes
  - 1/2/3: parameter presets
  - Q/A: sigma +/-
  - W/S: rho +/-
  - E/D: beta +/-
  - Up/Down: steps per frame +/-
  - Left/Right: dt -/+
  - [ / ]: max trail points -/+
*/

ArrayList<PVector> trail = new ArrayList<PVector>();
PVector state = new PVector(0.01, 0.0, 0.0);

float sigma = 10.0;
float rho = 28.0;
float beta = 8.0 / 3.0;

float dt = 0.008;
int stepsPerFrame = 8;
int maxTrailPoints = 12000;

float worldScale = 7.5;
float zoom = 700.0;
float rotateXCam = -0.42;
float rotateYCam = 0.78;
float panX = 0;
float panY = 0;

boolean paused = false;
boolean autoRotate = true;
boolean showAxes = true;

float autoRotateSpeed = 0.003;
int overlayFrames = 300;

void setup() {
  size(1200, 900, P3D);
  pixelDensity(1);
  colorMode(HSB, 360, 100, 100, 100);
  smooth(8);
  frameRate(120);
  trail.add(state.copy());
}

void draw() {
  if (!paused) {
    for (int i = 0; i < stepsPerFrame; i++) {
      state = integrateRK4(state, dt);
      trail.add(state.copy());
    }
    trimTrail();
  }

  background(0, 0, 6);
  lights();
  drawScene();
  drawOverlay();
}

void drawScene() {
  pushMatrix();
  translate(width * 0.5 + panX, height * 0.5 + panY, 0);
  scale(zoom / 700.0);
  rotateX(rotateXCam);
  rotateY(rotateYCam + (autoRotate ? frameCount * autoRotateSpeed : 0.0));

  if (showAxes) {
    drawAxes(220);
  }

  noFill();
  beginShape();
  int count = trail.size();
  for (int i = 0; i < count; i++) {
    PVector p = trail.get(i);
    float t = i / max(1.0, (float) (count - 1));
    float hueValue = (t * 320.0 + frameCount * 0.6) % 360.0;
    stroke(hueValue, 95, 100, 88);
    strokeWeight(1.5);
    vertex(p.x * worldScale, -p.y * worldScale, p.z * worldScale);
  }
  endShape();

  PVector last = trail.get(count - 1);
  pushMatrix();
  translate(last.x * worldScale, -last.y * worldScale, last.z * worldScale);
  noStroke();
  fill((frameCount * 2.5) % 360, 80, 100, 100);
  sphereDetail(8);
  sphere(5.5);
  popMatrix();

  popMatrix();
}

void drawAxes(float len) {
  strokeWeight(1.4);

  stroke(0, 90, 100, 80);
  line(0, 0, 0, len, 0, 0);

  stroke(130, 90, 100, 80);
  line(0, 0, 0, 0, -len, 0);

  stroke(220, 90, 100, 80);
  line(0, 0, 0, 0, 0, len);
}

void drawOverlay() {
  if (overlayFrames > 0) {
    overlayFrames--;
  }

  hint(DISABLE_DEPTH_TEST);
  camera();
  noLights();

  fill(0, 0, 100, 85);
  rect(14, 14, 700, 146, 10);

  fill(0, 0, 16, 100);
  textSize(14);
  text(
    "Lorenz Attractor Creator | FPS " + nf(frameRate, 2, 1) + " | points " + trail.size() + "/" + maxTrailPoints,
    24,
    38
  );
  text(
    "sigma(Q/A) " + nf(sigma, 1, 3) + "   rho(W/S) " + nf(rho, 1, 3) + "   beta(E/D) " + nf(beta, 1, 3),
    24,
    62
  );
  text(
    "dt(Left/Right) " + nf(dt, 1, 5) + "   steps(Up/Down) " + stepsPerFrame + "   zoom(wheel) " + nf(zoom, 1, 1),
    24,
    86
  );
  text(
    "Space pause | C clear | R reset | T auto-rotate | G axes | presets: 1 2 3 | [ ] trail",
    24,
    110
  );

  if (overlayFrames > 0) {
    fill(45, 100, 100, 95);
    text("Drag left = orbit, drag right = pan, wheel = zoom", 24, 134);
  }

  hint(ENABLE_DEPTH_TEST);
}

PVector integrateRK4(PVector s, float h) {
  PVector k1 = lorenzDerivative(s);
  PVector k2 = lorenzDerivative(PVector.add(s, PVector.mult(k1, h * 0.5)));
  PVector k3 = lorenzDerivative(PVector.add(s, PVector.mult(k2, h * 0.5)));
  PVector k4 = lorenzDerivative(PVector.add(s, PVector.mult(k3, h)));

  float nx = s.x + h / 6.0 * (k1.x + 2.0 * k2.x + 2.0 * k3.x + k4.x);
  float ny = s.y + h / 6.0 * (k1.y + 2.0 * k2.y + 2.0 * k3.y + k4.y);
  float nz = s.z + h / 6.0 * (k1.z + 2.0 * k2.z + 2.0 * k3.z + k4.z);
  return new PVector(nx, ny, nz);
}

PVector lorenzDerivative(PVector p) {
  float dx = sigma * (p.y - p.x);
  float dy = p.x * (rho - p.z) - p.y;
  float dz = p.x * p.y - beta * p.z;
  return new PVector(dx, dy, dz);
}

void trimTrail() {
  int overflow = trail.size() - maxTrailPoints;
  if (overflow > 0) {
    trail.subList(0, overflow).clear();
  }
}

void clearTrail() {
  trail.clear();
  trail.add(state.copy());
}

void resetAll() {
  sigma = 10.0;
  rho = 28.0;
  beta = 8.0 / 3.0;
  dt = 0.008;
  stepsPerFrame = 8;
  maxTrailPoints = 12000;

  state = new PVector(0.01, 0.0, 0.0);
  clearTrail();

  zoom = 700.0;
  rotateXCam = -0.42;
  rotateYCam = 0.78;
  panX = 0;
  panY = 0;
  autoRotate = true;
  showAxes = true;
  overlayFrames = 300;
}

void setPreset(int id) {
  if (id == 1) {
    sigma = 10.0;
    rho = 28.0;
    beta = 8.0 / 3.0;
  } else if (id == 2) {
    sigma = 16.0;
    rho = 45.92;
    beta = 4.0;
  } else if (id == 3) {
    sigma = 28.0;
    rho = 46.92;
    beta = 4.0;
  }
  clearTrail();
}

void keyPressed() {
  if (key == ' ') {
    paused = !paused;
  } else if (key == 'c' || key == 'C') {
    clearTrail();
  } else if (key == 'r' || key == 'R') {
    resetAll();
  } else if (key == 't' || key == 'T') {
    autoRotate = !autoRotate;
  } else if (key == 'g' || key == 'G') {
    showAxes = !showAxes;
  } else if (key == '1') {
    setPreset(1);
  } else if (key == '2') {
    setPreset(2);
  } else if (key == '3') {
    setPreset(3);
  } else if (key == 'q' || key == 'Q') {
    sigma += 0.2;
    clearTrail();
  } else if (key == 'a' || key == 'A') {
    sigma = max(0.1, sigma - 0.2);
    clearTrail();
  } else if (key == 'w' || key == 'W') {
    rho += 0.5;
    clearTrail();
  } else if (key == 's' || key == 'S') {
    rho = max(0.1, rho - 0.5);
    clearTrail();
  } else if (key == 'e' || key == 'E') {
    beta += 0.05;
    clearTrail();
  } else if (key == 'd' || key == 'D') {
    beta = max(0.05, beta - 0.05);
    clearTrail();
  } else if (keyCode == UP) {
    stepsPerFrame = min(80, stepsPerFrame + 1);
  } else if (keyCode == DOWN) {
    stepsPerFrame = max(1, stepsPerFrame - 1);
  } else if (keyCode == RIGHT) {
    dt = min(0.03, dt + 0.0005);
  } else if (keyCode == LEFT) {
    dt = max(0.0003, dt - 0.0005);
  } else if (key == '[') {
    maxTrailPoints = max(1000, maxTrailPoints - 1000);
    trimTrail();
  } else if (key == ']') {
    maxTrailPoints = min(50000, maxTrailPoints + 1000);
  }

  overlayFrames = 300;
}

void mouseDragged() {
  float dx = mouseX - pmouseX;
  float dy = mouseY - pmouseY;

  if (mouseButton == LEFT) {
    rotateYCam += dx * 0.008;
    rotateXCam += dy * 0.008;
    rotateXCam = constrain(rotateXCam, -PI * 0.49, PI * 0.49);
  } else if (mouseButton == RIGHT) {
    panX += dx;
    panY += dy;
  }

  overlayFrames = 300;
}

void mouseWheel(MouseEvent event) {
  float e = event.getCount();
  zoom *= pow(1.08, -e);
  zoom = constrain(zoom, 120.0, 2400.0);
  overlayFrames = 300;
}
