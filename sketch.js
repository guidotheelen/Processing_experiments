const state = {
  squareSize: 1,
  patternOffsetX: 0,
  patternOffsetY: 0,
  patternZoom: 1,
  minZoom: 0.25,
  maxZoom: 12,
  panningPattern: false,
  lastMouseX: 0,
  lastMouseY: 0,
  mFreq: 4,
  nFreq: 7,
  thickness: 0.02,
  density: 90000,
  contrast: 1,
  radialBias: 1,
};

const formatters = {
  mFreq: (value) => Number(value).toFixed(2),
  nFreq: (value) => Number(value).toFixed(2),
  thickness: (value) => Number(value).toFixed(3),
  density: (value) => `${Math.round(Number(value))}`,
  contrast: (value) => Number(value).toFixed(2),
  radialBias: (value) => Number(value).toFixed(2),
  offset: (value) => Number(value).toFixed(3),
  zoom: (value) => Number(value).toFixed(2),
};

const controls = [
  "mFreq",
  "nFreq",
  "thickness",
  "density",
  "contrast",
  "radialBias",
];

const shell = document.getElementById("sketch-shell");
const resetButton = document.getElementById("reset-view");

let plateDiameter = 0;
let plateRadius = 0;
let plateCX = 0;
let plateCY = 0;

controls.forEach((key) => {
  const input = document.getElementById(key);
  const output = document.getElementById(`${key}-value`);

  const sync = () => {
    const rawValue = input.value;
    state[key] = key === "density" ? Math.round(Number(rawValue)) : Number(rawValue);
    output.textContent = formatters[key](state[key]);
  };

  input.addEventListener("input", () => {
    sync();
    updateStatus();
    redrawSketch();
  });

  sync();
});

resetButton.addEventListener("click", () => {
  state.patternOffsetX = 0;
  state.patternOffsetY = 0;
  state.patternZoom = 1;
  updateStatus();
  redrawSketch();
});

function updateStatus() {
  document.getElementById("offsetX-value").textContent = formatters.offset(state.patternOffsetX);
  document.getElementById("offsetY-value").textContent = formatters.offset(state.patternOffsetY);
  document.getElementById("zoom-value").textContent = formatters.zoom(state.patternZoom);
}

function redrawSketch() {
  if (window.__p5Instance) {
    window.__p5Instance.redraw();
  }
}

function chladni(x, y, m, n) {
  return Math.sin(Math.PI * m * x) * Math.sin(Math.PI * n * y)
    - Math.sin(Math.PI * n * x) * Math.sin(Math.PI * m * y);
}

function insidePlate(x, y) {
  return Math.hypot(x - plateCX, y - plateCY) <= plateRadius;
}

function recomputePlateLayout(p) {
  const margin = 28;
  plateDiameter = Math.min(p.width - margin * 2, p.height - margin * 2) * 0.95;
  plateRadius = plateDiameter * 0.5;
  plateCX = p.width * 0.5;
  plateCY = p.height * 0.5;
}

updateStatus();

window.__p5Instance = new p5((p) => {
  function resizeToShell() {
    const nextWidth = Math.max(320, Math.floor(shell.clientWidth));
    const nextHeight = Math.max(420, Math.floor(shell.clientHeight));
    p.resizeCanvas(nextWidth, nextHeight, true);
    recomputePlateLayout(p);
    p.redraw();
  }

  function drawPattern() {
    p.background(0);
    p.loadPixels();

    for (let i = 0; i < state.density; i += 1) {
      const a = p.random(p.TWO_PI);
      const r = Math.sqrt(p.random()) * plateRadius;

      const dx = Math.cos(a) * r;
      const dy = Math.sin(a) * r;

      const px = Math.round(plateCX + dx);
      const py = Math.round(plateCY + dy);

      const u = (dx / plateRadius + 1) * 0.5;
      const v = (dy / plateRadius + 1) * 0.5;

      const zoomedU = (u - 0.5) / state.patternZoom + 0.5;
      const zoomedV = (v - 0.5) / state.patternZoom + 0.5;

      const sampleU = zoomedU + state.patternOffsetX;
      const sampleV = zoomedV + state.patternOffsetY;

      const value = chladni(sampleU, sampleV, state.mFreq, state.nFreq);

      let probability = Math.exp(-Math.abs(value) / state.thickness);
      probability = Math.pow(probability, state.contrast);

      const radial = r / plateRadius;
      const radialWeight = Math.pow(1 - radial, state.radialBias);
      probability *= radialWeight;

      if (p.random() < probability) {
        const index = 4 * (py * p.width + px);
        if (index >= 0 && index < p.pixels.length) {
          p.pixels[index] = 255;
          p.pixels[index + 1] = 255;
          p.pixels[index + 2] = 255;
          p.pixels[index + 3] = 255;
        }
      }
    }

    p.updatePixels();
  }

  function drawOverlay() {
    p.noFill();
    p.stroke(state.panningPattern ? 140 : 64);
    p.strokeWeight(1.2);
    p.circle(plateCX, plateCY, plateRadius * 2);

    p.noStroke();
    p.fill(255, 204);
    p.textAlign(p.LEFT, p.TOP);
    p.textSize(12);
    p.text("Pan inside the circle. Zoom with the mouse wheel.", 16, 16);
  }

  p.setup = () => {
    const canvas = p.createCanvas(320, 420);
    canvas.parent(shell);
    p.pixelDensity(1);
    p.frameRate(30);
    p.noLoop();
    p.textFont("Space Grotesk");

    recomputePlateLayout(p);
    resizeToShell();
  };

  p.draw = () => {
    drawPattern();
    drawOverlay();
  };

  p.windowResized = () => {
    resizeToShell();
  };

  p.mousePressed = () => {
    if (!insidePlate(p.mouseX, p.mouseY)) {
      return;
    }

    state.panningPattern = true;
    state.lastMouseX = p.mouseX;
    state.lastMouseY = p.mouseY;
  };

  p.mouseDragged = () => {
    if (!state.panningPattern) {
      return;
    }

    const dx = p.mouseX - state.lastMouseX;
    const dy = p.mouseY - state.lastMouseY;
    const zoomAdjustedPan = 1 / state.patternZoom;

    state.patternOffsetX -= (dx / plateDiameter) * zoomAdjustedPan;
    state.patternOffsetY -= (dy / plateDiameter) * zoomAdjustedPan;
    state.lastMouseX = p.mouseX;
    state.lastMouseY = p.mouseY;

    updateStatus();
    p.redraw();
  };

  p.mouseReleased = () => {
    state.panningPattern = false;
    p.redraw();
  };

  p.mouseWheel = (event) => {
    if (!insidePlate(p.mouseX, p.mouseY)) {
      return true;
    }

    const zoomFactor = 1 - event.deltaY * 0.0008;
    const nextZoom = p.constrain(state.patternZoom * zoomFactor, state.minZoom, state.maxZoom);

    const dx = p.mouseX - plateCX;
    const dy = p.mouseY - plateCY;

    const u = (dx / plateRadius + 1) * 0.5;
    const v = (dy / plateRadius + 1) * 0.5;

    const oldSampleU = (u - 0.5) / state.patternZoom + 0.5 + state.patternOffsetX;
    const oldSampleV = (v - 0.5) / state.patternZoom + 0.5 + state.patternOffsetY;

    state.patternZoom = nextZoom;
    state.patternOffsetX = oldSampleU - ((u - 0.5) / state.patternZoom + 0.5);
    state.patternOffsetY = oldSampleV - ((v - 0.5) / state.patternZoom + 0.5);

    updateStatus();
    p.redraw();
    return false;
  };

  p.keyPressed = () => {
    if (p.key !== "r" && p.key !== "R") {
      return;
    }

    state.patternOffsetX = 0;
    state.patternOffsetY = 0;
    state.patternZoom = 1;
    updateStatus();
    p.redraw();
  };
});
