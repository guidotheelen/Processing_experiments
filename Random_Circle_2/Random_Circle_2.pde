int squareSize = 1;
int screen_width = 700;
int screen_height = 700;

float maxRadius;

void settings() {
  size(screen_width, screen_height);
}

void setup() {
  frameRate(30);
  background(0);
  noStroke();
  fill(255);
  maxRadius = min(screen_width, screen_height) * 0.30;
}

void draw() {
  background(0);

  float center_x = screen_width / 2.0;
  float center_y = screen_height / 2.0;

  float t = frameCount * 2.0;
  float spacing = 30;
  float falloff = 5.0;

  for (int i = 0; i < 80000; i++) {
    float angle = random(TWO_PI);
    float radius = random(maxRadius);

    float d = abs(((radius - t) % spacing + spacing) % spacing);
    d = min(d, spacing - d);

    float probability = exp(-d / falloff);

    if (random(1) < probability) {
      float x = center_x + cos(angle) * radius;
      float y = center_y + sin(angle) * radius;
      square(x, y, squareSize);
    }
  }
}
