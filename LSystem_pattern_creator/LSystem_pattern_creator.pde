/*
  LSystem_pattern_creator.pde
  ---------------------------
  Interactive L-system pattern creator.

  Controls:
  - SPACE : random new pattern (preset + palette + parameters)
  - N     : next preset
  - R     : re-roll same preset
  - UP    : iterations +1
  - DOWN  : iterations -1
  - LEFT  : angle -1 degree
  - RIGHT : angle +1 degree
  - A     : toggle draw animation
  - H     : toggle HUD
  - S     : save PNG
*/

LSystemPreset[] presets;
int presetIndex = 0;

String sentence = "";
Segment[] segments = new Segment[0];

int iterations = 5;
float angleDeg = 60;

boolean animate = true;
boolean showHUD = true;

int drawProgress = 0;
int drawStep = 220;

float fitScale = 1;
float offsetX = 0;
float offsetY = 0;

float minX = 0;
float minY = 0;
float maxX = 0;
float maxY = 0;

float bgHue = 210;
float lineHueA = 30;
float lineHueB = 180;
float sat = 90;
float bri = 100;
float alphaLine = 86;

int patternId = 0;
int maxSymbols = 240000;

void setup() {
  size(1280, 800);
  pixelDensity(1);
  colorMode(HSB, 360, 100, 100, 100);
  smooth(4);
  textSize(14);

  presets = new LSystemPreset[] {
    new LSystemPreset(
      "Koch Snowflake",
      "F--F--F",
      new char[] {'F'},
      new String[] {"F+F--F+F"},
      "FGAB",
      60,
      3,
      6
    ),
    new LSystemPreset(
      "Fractal Plant",
      "X",
      new char[] {'X', 'F'},
      new String[] {"F+[[X]-X]-F[-FX]+X", "FF"},
      "F",
      25,
      4,
      7
    ),
    new LSystemPreset(
      "Sierpinski Arrowhead",
      "A",
      new char[] {'A', 'B'},
      new String[] {"B-A-B", "A+B+A"},
      "AB",
      60,
      4,
      10
    ),
    new LSystemPreset(
      "Dragon Curve",
      "FX",
      new char[] {'X', 'Y'},
      new String[] {"X+YF+", "-FX-Y"},
      "F",
      90,
      8,
      15
    ),
    new LSystemPreset(
      "Hilbert Curve",
      "A",
      new char[] {'A', 'B'},
      new String[] {"-BF+AFA+FB-", "+AF-BFB-FA+"},
      "F",
      90,
      2,
      6
    ),
    new LSystemPreset(
      "Branching Bush",
      "F",
      new char[] {'F'},
      new String[] {"FF-[-F+F+F]+[+F-F-F]"},
      "F",
      22.5,
      2,
      4
    )
  };

  randomizeAll();
}

void draw() {
  drawBackground();
  drawSegments();

  if (animate && drawProgress < segments.length) {
    drawProgress = min(segments.length, drawProgress + drawStep);
  }

  if (showHUD) {
    drawHUD();
  }
}

void drawBackground() {
  noStroke();
  float h1 = bgHue;
  float h2 = (bgHue + 28) % 360;

  for (int y = 0; y < height; y++) {
    float t = y / float(height - 1);
    float h = lerp(h1, h2, t);
    float s = 35 + 18 * sin(TWO_PI * t);
    float b = 9 + 10 * t;
    fill(h, s, b);
    rect(0, y, width, 1);
  }
}

void drawSegments() {
  if (segments.length == 0) return;

  int count = animate ? drawProgress : segments.length;
  count = constrain(count, 0, segments.length);

  float sw = map(fitScale, 3, 30, 0.6, 2.3);
  sw = constrain(sw, 0.45, 2.8);
  strokeWeight(sw);
  noFill();

  for (int i = 0; i < count; i++) {
    Segment seg = segments[i];
    float x1 = seg.x1 * fitScale + offsetX;
    float y1 = seg.y1 * fitScale + offsetY;
    float x2 = seg.x2 * fitScale + offsetX;
    float y2 = seg.y2 * fitScale + offsetY;

    float t = (segments.length <= 1) ? 0 : i / float(segments.length - 1);
    float h = lerp(lineHueA, lineHueB, t);
    float s = sat - seg.depth * 3.0;
    float b = bri - seg.depth * 2.0;

    stroke((h + 360) % 360, constrain(s, 30, 100), constrain(b, 35, 100), alphaLine);
    line(x1, y1, x2, y2);
  }
}

void drawHUD() {
  LSystemPreset p = presets[presetIndex];

  String status = animate
    ? ("animated " + drawProgress + "/" + segments.length)
    : ("static " + segments.length + " segments");

  fill(0, 0, 0, 45);
  noStroke();
  rect(18, 18, 600, 128, 10);

  fill(0, 0, 100, 92);
  textAlign(LEFT, TOP);
  text(
    "L-system Pattern Creator\n"
    + "Preset: " + p.name + " | Iterations: " + iterations + " | Angle: " + nf(angleDeg, 1, 2) + " deg\n"
    + "Pattern ID: " + patternId + " | Sentence size: " + sentence.length() + " chars | " + status + "\n"
    + "SPACE new pattern, N next preset, R reroll, arrows angle/iterations, A animate, S save, H hide HUD",
    30,
    30
  );
}

void keyPressed() {
  if (key == ' ' ) {
    randomizeAll();
  } else if (key == 'n' || key == 'N') {
    presetIndex = (presetIndex + 1) % presets.length;
    randomizeCurrentPreset();
  } else if (key == 'r' || key == 'R') {
    randomizeCurrentPreset();
  } else if (keyCode == UP) {
    iterations = min(iterations + 1, presets[presetIndex].maxIter);
    rebuildPattern();
  } else if (keyCode == DOWN) {
    iterations = max(iterations - 1, presets[presetIndex].minIter);
    rebuildPattern();
  } else if (keyCode == LEFT) {
    angleDeg -= 1;
    rebuildPattern();
  } else if (keyCode == RIGHT) {
    angleDeg += 1;
    rebuildPattern();
  } else if (key == 'a' || key == 'A') {
    animate = !animate;
    if (!animate) drawProgress = segments.length;
    if (animate) drawProgress = 0;
  } else if (key == 'h' || key == 'H') {
    showHUD = !showHUD;
  } else if (key == 's' || key == 'S') {
    saveFrame("lsystem_pattern_####.png");
  }
}

void randomizeAll() {
  presetIndex = (int) random(presets.length);
  randomizeCurrentPreset();
}

void randomizeCurrentPreset() {
  LSystemPreset p = presets[presetIndex];

  iterations = (int) random(p.minIter, p.maxIter + 1);
  angleDeg = p.baseAngle * random(0.88, 1.12);

  bgHue = random(360);
  lineHueA = (bgHue + random(70, 180)) % 360;
  lineHueB = (lineHueA + random(25, 140)) % 360;
  sat = random(72, 100);
  bri = random(85, 100);
  alphaLine = random(62, 95);

  drawStep = (int) random(120, 460);

  rebuildPattern();
}

void rebuildPattern() {
  patternId++;

  sentence = buildSentence(
    presets[presetIndex],
    iterations,
    maxSymbols
  );

  segments = buildSegments(sentence, presets[presetIndex].drawSymbols, radians(angleDeg));
  computeBoundsAndFit(segments);

  drawProgress = animate ? 0 : segments.length;
}

String buildSentence(LSystemPreset p, int iter, int maxLen) {
  String current = p.axiom;

  for (int i = 0; i < iter; i++) {
    StringBuilder next = new StringBuilder(max(current.length() * 2, 32));

    for (int j = 0; j < current.length(); j++) {
      char c = current.charAt(j);
      String repl = p.getRule(c);
      if (repl != null) next.append(repl);
      else next.append(c);

      if (next.length() > maxLen) {
        current = next.toString();
        return current;
      }
    }

    current = next.toString();
  }

  return current;
}

Segment[] buildSegments(String src, String drawSymbols, float angleRad) {
  ArrayList<Segment> list = new ArrayList<Segment>();
  ArrayList<TurtleState> stack = new ArrayList<TurtleState>();

  float x = 0;
  float y = 0;
  float heading = -HALF_PI;
  int depth = 0;

  for (int i = 0; i < src.length(); i++) {
    char c = src.charAt(i);

    if (isDrawSymbol(c, drawSymbols)) {
      float nx = x + cos(heading);
      float ny = y + sin(heading);
      list.add(new Segment(x, y, nx, ny, depth));
      x = nx;
      y = ny;
    } else if (c == 'f') {
      x += cos(heading);
      y += sin(heading);
    } else if (c == '+') {
      heading += angleRad;
    } else if (c == '-') {
      heading -= angleRad;
    } else if (c == '[') {
      stack.add(new TurtleState(x, y, heading, depth));
      depth++;
    } else if (c == ']') {
      if (stack.size() > 0) {
        TurtleState t = stack.remove(stack.size() - 1);
        x = t.x;
        y = t.y;
        heading = t.heading;
        depth = t.depth;
      }
    }
  }

  Segment[] arr = new Segment[list.size()];
  list.toArray(arr);
  return arr;
}

boolean isDrawSymbol(char c, String drawSymbols) {
  return drawSymbols.indexOf(c) >= 0;
}

void computeBoundsAndFit(Segment[] segs) {
  if (segs.length == 0) {
    minX = -1;
    maxX = 1;
    minY = -1;
    maxY = 1;
    fitScale = 1;
    offsetX = width * 0.5;
    offsetY = height * 0.5;
    return;
  }

  minX = Float.MAX_VALUE;
  minY = Float.MAX_VALUE;
  maxX = -Float.MAX_VALUE;
  maxY = -Float.MAX_VALUE;

  for (int i = 0; i < segs.length; i++) {
    Segment s = segs[i];
    minX = min(minX, min(s.x1, s.x2));
    minY = min(minY, min(s.y1, s.y2));
    maxX = max(maxX, max(s.x1, s.x2));
    maxY = max(maxY, max(s.y1, s.y2));
  }

  float margin = 60;
  float spanX = max(0.0001, maxX - minX);
  float spanY = max(0.0001, maxY - minY);

  float sx = (width - 2 * margin) / spanX;
  float sy = (height - 2 * margin) / spanY;
  fitScale = min(sx, sy);

  float cx = (minX + maxX) * 0.5;
  float cy = (minY + maxY) * 0.5;

  offsetX = width * 0.5 - cx * fitScale;
  offsetY = height * 0.5 - cy * fitScale;
}

class Segment {
  float x1;
  float y1;
  float x2;
  float y2;
  int depth;

  Segment(float x1, float y1, float x2, float y2, int depth) {
    this.x1 = x1;
    this.y1 = y1;
    this.x2 = x2;
    this.y2 = y2;
    this.depth = depth;
  }
}

class TurtleState {
  float x;
  float y;
  float heading;
  int depth;

  TurtleState(float x, float y, float heading, int depth) {
    this.x = x;
    this.y = y;
    this.heading = heading;
    this.depth = depth;
  }
}

class LSystemPreset {
  String name;
  String axiom;
  char[] ruleKeys;
  String[] ruleValues;
  String drawSymbols;
  float baseAngle;
  int minIter;
  int maxIter;

  LSystemPreset(
    String name,
    String axiom,
    char[] ruleKeys,
    String[] ruleValues,
    String drawSymbols,
    float baseAngle,
    int minIter,
    int maxIter
  ) {
    this.name = name;
    this.axiom = axiom;
    this.ruleKeys = ruleKeys;
    this.ruleValues = ruleValues;
    this.drawSymbols = drawSymbols;
    this.baseAngle = baseAngle;
    this.minIter = minIter;
    this.maxIter = maxIter;
  }

  String getRule(char c) {
    for (int i = 0; i < ruleKeys.length; i++) {
      if (ruleKeys[i] == c) return ruleValues[i];
    }
    return null;
  }
}
