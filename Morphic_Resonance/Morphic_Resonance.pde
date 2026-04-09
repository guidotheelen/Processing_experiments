int squareSize = 1;
int screen_width = 700;
int screen_height = 760; // extra space for slider

// Slider
float sliderX = 80;
float sliderY = 720;
float sliderW = 540;
float sliderH = 16;
float sliderMin = 0.2;
float sliderMax = 20.0;
float frequency = 6.0;
boolean draggingSlider = false;

// Visual settings
float time = 0.0;
float timeSpeed = 0.03;

void settings() {
  size(screen_width, screen_height);
}

void setup() {
  surface.setTitle("Morphic Resonance Generator");
  noStroke();
}

void draw() {
  background(0);

  // Animate over time
  time += timeSpeed;

  // Draw resonance field
  drawResonanceField();

  // Divider above slider area
  stroke(80);
  line(0, 700, width, 700);
  noStroke();

  // Draw slider UI
  drawSlider();

  // Labels
  fill(255);
  textSize(16);
  textAlign(LEFT, CENTER);
  text("Frequency: " + nf(frequency, 1, 2), 80, 690);

  textSize(12);
  fill(180);
  text("Drag the slider to change the resonance frequency", 80, 745);
}

void drawResonanceField() {
  for (int y = 0; y < 700; y += squareSize) {
    for (int x = 0; x < width; x += squareSize) {
      float nx = map(x, 0, width, -2.0, 2.0);
      float ny = map(y, 0, 700, -2.0, 2.0);

      float d1 = dist(nx, ny, -0.7, -0.3);
      float d2 = dist(nx, ny,  0.8,  0.5);
      float d3 = dist(nx, ny,  0.0,  0.0);

      // Layered standing-wave style field
      float wave1 = sin((d1 * frequency * 6.0) - time * 2.0);
      float wave2 = cos((d2 * frequency * 5.0) + time * 1.7);
      float wave3 = sin((d3 * frequency * 8.0) - time * 1.2);

      // Angular modulation for more "morphic" complexity
      float angle = atan2(ny, nx);
      float spiral = sin(angle * frequency + time);

      float v = (wave1 + wave2 + wave3 + spiral) * 0.25;

      // Convert to glowing palette
      float brightness = map(v, -1, 1, 0, 255);
      float r = brightness;
      float g = 100 + brightness * 0.5;
      float b = 255 - brightness * 0.4;

      fill(constrain(r, 0, 255), constrain(g, 0, 255), constrain(b, 0, 255));
      rect(x, y, squareSize, squareSize);
    }
  }
}

void drawSlider() {
  // Track
  fill(50);
  rect(sliderX, sliderY, sliderW, sliderH, 8);

  // Active fill
  float knobX = getSliderKnobX();
  fill(100, 180, 255);
  rect(sliderX, sliderY, knobX - sliderX, sliderH, 8);

  // Knob
  fill(255);
  ellipse(knobX, sliderY + sliderH / 2, 22, 22);

  // Min/max labels
  fill(180);
  textSize(12);
  textAlign(CENTER, TOP);
  text(nf(sliderMin, 1, 1), sliderX, sliderY + 24);
  text(nf(sliderMax, 1, 1), sliderX + sliderW, sliderY + 24);
}

float getSliderKnobX() {
  return map(frequency, sliderMin, sliderMax, sliderX, sliderX + sliderW);
}

void updateSlider() {
  float clampedX = constrain(mouseX, sliderX, sliderX + sliderW);
  frequency = map(clampedX, sliderX, sliderX + sliderW, sliderMin, sliderMax);
}

void mousePressed() {
  float knobX = getSliderKnobX();
  if (dist(mouseX, mouseY, knobX, sliderY + sliderH / 2) < 16 ||
      (mouseX >= sliderX && mouseX <= sliderX + sliderW &&
       mouseY >= sliderY - 10 && mouseY <= sliderY + sliderH + 10)) {
    draggingSlider = true;
    updateSlider();
  }
}

void mouseDragged() {
  if (draggingSlider) {
    updateSlider();
  }
}

void mouseReleased() {
  draggingSlider = false;
}
