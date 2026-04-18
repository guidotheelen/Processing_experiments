import java.io.File;
import java.util.Arrays;

String inputFileName = ""; // Optional: set a specific filename. Leave empty to auto-pick first image in this folder.

int canvasWidth = 700;
int canvasHeight = 700;
int pointSize = 2;

int particleCount = 30000;
float brightnessThreshold = 0.06;
float spawnBias = 5.4;
int spawnAttempts = 36;

float driftStrength = 0.1;
float lightAttractStrength = 1.6;
float velocityDamping = 2.0;
float maxSpeed = 1.5;
float brightStickiness = 0.90;
float darkRespawnChance = 0.5;
float gradientSampleDistance = 5.0;
int minSwirlFrames = 70;
int respawnDelayJitter = 80;
int fadeInFrames = 5;
int fadeOutFrames = 5;
float darkAreaDimScale = 0.5; // Alpha scale when particle is on a dark area.
float darkDimGamma = 2.2; // >1 makes dimming stronger away from bright areas.

float centerSwirlStrength = 0.5;
float centerPullStrength = 0.03;
float edgeVelocityScale = 0.8; // Lower values make particles slower near the outer radius.
float radialSlowdownRadiusScale = 2.1; // >1 pushes slowdown ring farther out.
float offscreenRespawnMargin = 280; // Allow particles to travel well beyond screen bounds.

float spiralAngleStep = 0.1;
float spiralRadiusStep = 0.6;
float spiralJitter = 150.0;
float spiralCenterYOffset = -35.0;

boolean keepAspectRatio = true;

int recordFPS = 30;
float clipDurationSeconds = 12.0;
boolean exportFrames = true;
int maxExportFrames = 360;
String exportPattern = "clip/float-####.png";

PImage sourceImage;
int drawWidth;
int drawHeight;
int offsetX;
int offsetY;
Particle[] particles;
float spiralCenterX;
float spiralCenterY;
float spiralRadiusCursor;
float spiralAngleCursor;
float spiralMaxRadius;

void settings() {
  size(canvasWidth, canvasHeight);
}

void setup() {
  frameRate(recordFPS);
  background(0);
  noStroke();
  fill(255);

  sourceImage = loadInputImage();

  if (sourceImage == null) {
    println("No input image found. Put an image in: " + sketchPath());
    println("Or set inputFileName to an explicit file in this sketch folder.");
    noLoop();
    return;
  }

  sourceImage.loadPixels();
  computeDrawArea();
  resetSpiral();
  initParticles();
  maxExportFrames = max(1, round(clipDurationSeconds * recordFPS));

  println("Loaded image: " + sourceImage.width + "x" + sourceImage.height);
  if (exportFrames) {
    println("Recording clip frames: " + maxExportFrames + " at " + recordFPS + " FPS");
    println("Output pattern: " + exportPattern);
  }
}

void draw() {
  if (sourceImage == null) {
    return;
  }

  background(0);

  for (int i = 0; i < particles.length; i++) {
    particles[i].update();
    particles[i].render();
  }

  if (exportFrames) {
    saveFrame(exportPattern);
    if (frameCount >= maxExportFrames) {
      println("Finished exporting " + maxExportFrames + " frames.");
      exit();
    }
  }
}

void initParticles() {
  particles = new Particle[particleCount];
  for (int i = 0; i < particles.length; i++) {
    particles[i] = new Particle();
    particles[i].respawn(true);
  }
}

float brightnessAtCanvas(float x, float y) {
  if (x < offsetX || y < offsetY || x >= offsetX + drawWidth || y >= offsetY + drawHeight) {
    return 0;
  }

  float u = (x - offsetX) / max(1, drawWidth - 1);
  float v = (y - offsetY) / max(1, drawHeight - 1);

  int srcX = int(constrain(round(u * (sourceImage.width - 1)), 0, sourceImage.width - 1));
  int srcY = int(constrain(round(v * (sourceImage.height - 1)), 0, sourceImage.height - 1));

  color c = sourceImage.pixels[srcY * sourceImage.width + srcX];
  return brightness(c) / 255.0;
}

boolean chooseBrightSpawnPosition(Particle p) {
  float bestX = random(offsetX, offsetX + drawWidth);
  float bestY = random(offsetY, offsetY + drawHeight);
  float bestB = -1;

  for (int i = 0; i < spawnAttempts; i++) {
    float[] candidate = nextSpiralSpawnPoint();
    float x = candidate[0];
    float y = candidate[1];

    float b = brightnessAtCanvas(x, y);
    float weight = pow(max(0, (b - brightnessThreshold) / (1.0 - brightnessThreshold)), spawnBias);

    if (random(1) < weight) {
      p.x = x;
      p.y = y;
      return true;
    }

    if (b > bestB) {
      bestB = b;
      bestX = x;
      bestY = y;
    }
  }

  p.x = bestX;
  p.y = bestY;
  return false;
}

class Particle {
  float x;
  float y;
  float vx;
  float vy;
  float opacity;
  int age;
  int respawnDelayFrames;
  boolean fadingOut;

  void respawn(boolean zeroVelocity) {
    chooseBrightSpawnPosition(this);

    if (zeroVelocity) {
      vx = 0;
      vy = 0;
    } else {
      vx *= 0.25;
      vy *= 0.25;
    }

    respawnDelayFrames = minSwirlFrames + int(random(respawnDelayJitter + 1));
    age = int(random(respawnDelayFrames + 1));
    opacity = 0;
    fadingOut = false;
  }

  void update() {
    age++;

    float b = brightnessAtCanvas(x, y);
    float d = max(1, gradientSampleDistance);

    float gx = brightnessAtCanvas(x + d, y) - brightnessAtCanvas(x - d, y);
    float gy = brightnessAtCanvas(x, y + d) - brightnessAtCanvas(x, y - d);

    float ax = gx * lightAttractStrength + random(-driftStrength, driftStrength);
    float ay = gy * lightAttractStrength + random(-driftStrength, driftStrength);

    float dx = x - spiralCenterX;
    float dy = y - spiralCenterY;
    float dist = max(1, sqrt(dx * dx + dy * dy));
    float nx = dx / dist;
    float ny = dy / dist;
    float tx = -ny;
    float ty = nx;
    float swirlRadius = max(1, spiralMaxRadius * radialSlowdownRadiusScale);
    float swirlFalloff = 1.0 - constrain(dist / swirlRadius, 0, 1);
    float swirl = centerSwirlStrength * (0.35 + 0.65 * swirlFalloff);

    ax += tx * swirl;
    ay += ty * swirl;

    ax -= nx * centerPullStrength;
    ay -= ny * centerPullStrength;

    vx = (vx + ax) * velocityDamping;
    vy = (vy + ay) * velocityDamping;

    float speed = sqrt(vx * vx + vy * vy);
    if (speed > maxSpeed) {
      float s = maxSpeed / speed;
      vx *= s;
      vy *= s;
    }

    // In brighter areas, particles move more slowly and appear to "stick".
    float moveScale = lerp(1.0, 0.32, constrain(b * brightStickiness, 0, 1));
    float radialNorm = constrain(dist / swirlRadius, 0, 1);
    float radialSpeedScale = lerp(1.0, edgeVelocityScale, radialNorm);
    x += vx * moveScale * radialSpeedScale;
    y += vy * moveScale * radialSpeedScale;

    if (!fadingOut) {
      if (x < -offscreenRespawnMargin || x > width + offscreenRespawnMargin
        || y < -offscreenRespawnMargin || y > height + offscreenRespawnMargin) {
        fadingOut = true;
      }
    }

    float localB = brightnessAtCanvas(x, y);
    float darkness = 1.0 - localB;
    if (!fadingOut && age > respawnDelayFrames && random(1) < darkRespawnChance * darkness) {
      fadingOut = true;
    }

    if (fadingOut) {
      opacity -= 1.0 / max(1, fadeOutFrames);
      if (opacity <= 0) {
        respawn(false);
        return;
      }
    } else {
      opacity += 1.0 / max(1, fadeInFrames);
    }

    opacity = constrain(opacity, 0, 1);
  }

  void render() {
    if (opacity <= 0.01) {
      return;
    }

    float localB = brightnessAtCanvas(x, y);
    float lightMix = constrain((localB - brightnessThreshold) / (1.0 - brightnessThreshold), 0, 1);
    lightMix = pow(lightMix, darkDimGamma);
    float areaAlphaScale = lerp(darkAreaDimScale, 1.0, lightMix);
    fill(255, 255 * opacity * areaAlphaScale);
    square(x, y, pointSize);
  }
}

PImage loadInputImage() {
  if (inputFileName != null && inputFileName.trim().length() > 0) {
    String explicitPath = sketchPath(inputFileName.trim());
    PImage explicitImage = loadImage(explicitPath);
    if (explicitImage != null) {
      return explicitImage;
    }
    println("Could not load inputFileName: " + explicitPath);
  }

  File folder = new File(sketchPath());
  File[] files = folder.listFiles();

  if (files == null) {
    return null;
  }

  Arrays.sort(files);

  for (File file : files) {
    if (!file.isFile()) {
      continue;
    }

    String name = file.getName().toLowerCase();
    if (hasImageExtension(name)) {
      PImage img = loadImage(file.getAbsolutePath());
      if (img != null) {
        println("Using image file: " + file.getName());
        return img;
      }
    }
  }

  return null;
}

boolean hasImageExtension(String fileName) {
  return fileName.endsWith(".png")
    || fileName.endsWith(".jpg")
    || fileName.endsWith(".jpeg")
    || fileName.endsWith(".gif")
    || fileName.endsWith(".bmp")
    || fileName.endsWith(".tif")
    || fileName.endsWith(".tiff")
    || fileName.endsWith(".webp");
}

void resetSpiral() {
  spiralCenterX = offsetX + drawWidth / 2.0;
  spiralCenterY = offsetY + drawHeight / 2.0 + spiralCenterYOffset;
  spiralRadiusCursor = 0;
  spiralAngleCursor = random(TWO_PI);
  spiralMaxRadius = min(drawWidth, drawHeight) * 0.5;
}

float[] nextSpiralSpawnPoint() {
  float radius = spiralRadiusCursor;
  float angle = spiralAngleCursor;

  float x = spiralCenterX + cos(angle) * radius + random(-spiralJitter, spiralJitter);
  float y = spiralCenterY + sin(angle) * radius + random(-spiralJitter, spiralJitter);

  spiralAngleCursor += spiralAngleStep;
  spiralRadiusCursor += spiralRadiusStep;

  if (spiralRadiusCursor > spiralMaxRadius) {
    spiralRadiusCursor = 0;
  }

  x = constrain(x, offsetX, offsetX + drawWidth - 1);
  y = constrain(y, offsetY, offsetY + drawHeight - 1);
  return new float[] {x, y};
}

void computeDrawArea() {
  if (!keepAspectRatio) {
    drawWidth = width;
    drawHeight = height;
    offsetX = 0;
    offsetY = 0;
    return;
  }

  float scaleX = (float) width / sourceImage.width;
  float scaleY = (float) height / sourceImage.height;
  float scale = min(scaleX, scaleY);

  drawWidth = max(1, round(sourceImage.width * scale));
  drawHeight = max(1, round(sourceImage.height * scale));

  offsetX = (width - drawWidth) / 2;
  offsetY = (height - drawHeight) / 2;
}
