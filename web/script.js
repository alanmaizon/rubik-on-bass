import * as THREE from 'three';
import { OrbitControls } from 'three/addons/controls/OrbitControls.js';

// --- Global State ---
let scene, camera, renderer, controls, rubikCube;
let isAnimating = false, rotationQueue = [], currentAnimation = null;
let currentFrontFaceStickers = [], arpeggioSequence = null, isPlaying = false;
const mutedStickers = new Set();
let sampler; // Audio player
let allCubies = [];
let currentBaseNoteDuration = '16n';
let isHalfLength = false;
let touchStartX, touchStartY, isDragging;
let touchStartTime; 

// --- Constants ---
const CUBE_COLORS = { WHITE: 0xffffff, RED: 0xb71234, YELLOW: 0xffd500, ORANGE: 0xff5800, GREEN: 0x009b48, BLUE: 0x0046ad, BLACK: 0x111111 };
const CUBE_MOVES = {
    'U': { axis: 'y', layers: [1.5], sign: -1 }, 'u': { axis: 'y', layers: [0.5], sign: -1 }, 'D': { axis: 'y', layers: [-1.5], sign: 1 },
    'd': { axis: 'y', layers: [-0.5], sign: 1 }, 'L': { axis: 'x', layers: [-1.5], sign: 1 }, 'l': { axis: 'x', layers: [-0.5], sign: 1 },
    'R': { axis: 'x', layers: [1.5], sign: -1 }, 'r': { axis: 'x', layers: [0.5], sign: -1 }, 'F': { axis: 'z', layers: [1.5], sign: -1 },
    'f': { axis: 'z', layers: [0.5], sign: -1 }, 'B': { axis: 'z', layers: [-1.5], sign: 1 }, 'b': { axis: 'z', layers: [-0.5], sign: 1 }
};
const COLOR_TO_NOTE_MAP = { [CUBE_COLORS.WHITE]: 'C4', [CUBE_COLORS.RED]: 'D4', [CUBE_COLORS.BLUE]: 'E4', [CUBE_COLORS.ORANGE]: 'G4', [CUBE_COLORS.GREEN]: 'A4', [CUBE_COLORS.YELLOW]: 'C5', [CUBE_COLORS.BLACK]: null };

// --- Asset Loading ---
function loadAudioAssets() {
    const toggleLoopBtn = document.getElementById('toggleLoopBtn');
    const synthSamples = { 'C4': 'white.wav', 'D4': 'red.wav', 'E4': 'blue.wav', 'G4': 'orange.wav', 'A4': 'green.wav', 'C5': 'yellow.wav' };
    sampler = new Tone.Sampler({ urls: synthSamples, baseUrl: "./", onload: () => {
        console.log('Audio samples loaded successfully.');
        if (toggleLoopBtn) { toggleLoopBtn.disabled = false; toggleLoopBtn.textContent = 'Play'; }
    }}).toDestination();
}

// --- Core Functions ---
function init() {
    scene = new THREE.Scene();
    scene.background = new THREE.Color(0x2d2d2d);
    const container = document.getElementById('container');
    camera = new THREE.PerspectiveCamera(75, container.clientWidth / container.clientHeight, 0.1, 1000);
    camera.position.set(0, 2, 6);
    renderer = new THREE.WebGLRenderer({ antialias: true });
    renderer.setSize(container.clientWidth, container.clientHeight);
    container.appendChild(renderer.domElement);
    scene.add(new THREE.AmbientLight(0xffffff, 1.0));
    const dirLight = new THREE.DirectionalLight(0xffffff, 0.8);
    dirLight.position.set(5, 10, 7.5);
    scene.add(dirLight);
    controls = new OrbitControls(camera, renderer.domElement);
    controls.enableDamping = true;
    createRubikCube();
    setupEventListeners();
    setTimeout(onInteractionEnd, 100);
    loadAudioAssets();
}

function animate() {
    requestAnimationFrame(animate);
    controls.update();
    if (isAnimating && currentAnimation) {
        const { group, axis, targetAngle, onComplete } = currentAnimation;
        const increment = 0.1 * Math.sign(targetAngle);
        currentAnimation.currentAngle += increment;
        if (Math.abs(currentAnimation.currentAngle) >= Math.abs(targetAngle)) onComplete();
        else group.quaternion.setFromAxisAngle(axis, currentAnimation.currentAngle);
    }
    renderer.render(scene, camera);
}

// --- Event Listener Setup ---
function setupEventListeners() {
    window.addEventListener('resize', onWindowResize, false);
    controls.addEventListener('end', onInteractionEnd);

    // --- NEW: Mobile Touch and Menu Listeners ---
    const menuToggleBtn = document.getElementById('menu-toggle-btn');
    menuToggleBtn.addEventListener('click', () => {
        document.getElementById('side-menu').classList.toggle('is-open');
    });
    renderer.domElement.addEventListener('click', handleCanvasClick, false);
    renderer.domElement.addEventListener('touchstart', handleTouchStart, false);
    renderer.domElement.addEventListener('touchmove', handleTouchMove, false);
    renderer.domElement.addEventListener('touchend', handleTouchEnd, false);

    const moveMap = { 'U':'U','U_prime':'U','u_inner':'u','u_inner_prime':'u','D':'D','D_prime':'D','d_inner':'d','d_inner_prime':'d','L':'L','L_prime':'L','l_inner':'l','l_inner_prime':'l','R':'R','R_prime':'R','r_inner':'r','r_inner_prime':'r' };
    for (const [btnId, move] of Object.entries(moveMap)) {
        document.getElementById(`btn_${btnId}`)?.addEventListener('click', () => rotateFace(move, !btnId.includes('_prime')));
    }
    document.getElementById('toggleLoopBtn')?.addEventListener('click', () => isPlaying ? stopSequencer() : startSequencer());
    document.getElementById('playRandomBtn')?.addEventListener('click', scrambleCube);
    document.getElementById('resetCubeBtn')?.addEventListener('click', resetCube);
    document.getElementById('muteAllBtn')?.addEventListener('click', () => muteAllStickers(true));
    document.getElementById('unmuteAllBtn')?.addEventListener('click', () => muteAllStickers(false));
    
    const bpmInput = document.getElementById('bpmInput');
    const bpmSlider = document.getElementById('bpmSlider');

    const setBpm = (value) => {
        const bpm = Math.max(20, Math.min(200, parseInt(value) || 120));
        Tone.Transport.bpm.value = bpm;
        bpmInput.value = bpm;
        bpmSlider.value = bpm;
    };

    bpmInput.addEventListener('input', (e) => setBpm(e.target.value));
    bpmSlider.addEventListener('input', (e) => setBpm(e.target.value));
    
    setBpm(120); // Set initial BPM

    // NEW: Event listener for the half-length switch
    const halfLengthSwitch = document.getElementById('halfLengthSwitch');
    halfLengthSwitch.addEventListener('change', () => {
        isHalfLength = halfLengthSwitch.checked;
        if (isPlaying) {
            startSequencer(); // Restart loop to apply the change
        }
    });
}

// --- Sequencer & Master Controls ---
async function startSequencer() {
    await Tone.start();
    if (currentFrontFaceStickers.length < 16) return;
    
    // NEW: Calculate the note duration based on the switch state
    let noteDuration = currentBaseNoteDuration;
    if (isHalfLength) {
        const baseValue = parseInt(currentBaseNoteDuration.replace('n', ''));
        noteDuration = `${baseValue * 2}n`; // e.g., '16n' becomes '32n'
    }
    console.log(`Using note duration: ${noteDuration}`);

    const data = currentFrontFaceStickers.map(s => ({ note: COLOR_TO_NOTE_MAP[s.color], ...s, id: `x:${s.cubie.userData.originalPosition.x},y:${s.cubie.userData.originalPosition.y},z:${s.cubie.userData.originalPosition.z}_face:${s.faceName}` }));
    if (arpeggioSequence) arpeggioSequence.dispose();
    
    arpeggioSequence = new Tone.Sequence((time, d) => {
        if (mutedStickers.has(d.id) || !d.note) return;
        sampler.triggerAttackRelease(d.note, noteDuration, time); // Use the calculated duration
        const mat = d.cubie.material[getMaterialIndexForFace(d.faceName)];
        if (mat) { mat.emissive.setHex(d.color); mat.emissiveIntensity = 0.8; setTimeout(() => mat.emissiveIntensity = 0, 100); }
    }, data, "16n").start(0);
    arpeggioSequence.loop = true;
    Tone.Transport.start();
    isPlaying = true;
    document.getElementById('toggleLoopBtn').textContent = 'Stop';
}

function stopSequencer() {
    if (arpeggioSequence) arpeggioSequence.dispose();
    Tone.Transport.stop();
    isPlaying = false;
    document.getElementById('toggleLoopBtn').textContent = 'Play';
}

function resetCube() {
    // 1. Stop all audio
    stopSequencer();

    // 2. Immediately stop any new animation from starting or continuing
    isAnimating = false;
    rotationQueue = [];

    // 3. If an animation was in progress, explicitly remove its temporary group
    if (currentAnimation && currentAnimation.group) {
        scene.remove(currentAnimation.group);
    }
    currentAnimation = null; // Clear the animation object

    // 4. Remove the main cube group
    if (rubikCube) {
        scene.remove(rubikCube);
    }

    // 5. Dispose of ALL cubies using our definitive list to prevent memory leaks
    allCubies.forEach(cubie => {
        cubie.geometry.dispose();
        if (Array.isArray(cubie.material)) {
            cubie.material.forEach(mat => mat.dispose());
        }
    });
    allCubies = []; // Clear the array for the next creation

    // 6. Reset other states and rebuild the cube
    mutedStickers.clear();
    createRubikCube();
    onInteractionEnd(); // Update sticker detection for the new cube

    console.log("Cube has been reset to solved state.");
}

function muteAllStickers(shouldMute) {
    if (shouldMute) {
        rubikCube.children.forEach(cubie => {
            Object.keys(cubie.userData.faceColors).forEach(faceName => {
                if (cubie.userData.faceColors[faceName] !== CUBE_COLORS.BLACK) {
                    const pos = cubie.userData.originalPosition;
                    const stickerId = `x:${pos.x},y:${pos.y},z:${pos.z}_face:${faceName}`;
                    mutedStickers.add(stickerId);
                }
            });
        });
        console.log("All stickers muted.");
    } else {
        mutedStickers.clear();
        console.log("All stickers unmuted.");
    }
    updateAllMuteVisuals();
    if (isPlaying) startSequencer();
}

// --- Cube Logic and Interaction ---
function createRubikCube() {
    allCubies = [];
    rubikCube = new THREE.Group();
    const size = 0.8, spacing = 0.05, extent = 1.5;
    for (let i = 0; i < 4; i++) for (let j = 0; j < 4; j++) for (let k = 0; k < 4; k++) {
        if (i > 0 && i < 3 && j > 0 && j < 3 && k > 0 && k < 3) continue;
        const p = { x: i - extent, y: j - extent, z: k - extent };
        const fc = { right: p.x === 1.5 ? CUBE_COLORS.BLUE : CUBE_COLORS.BLACK, left: p.x === -1.5 ? CUBE_COLORS.GREEN : CUBE_COLORS.BLACK, top: p.y === 1.5 ? CUBE_COLORS.YELLOW : CUBE_COLORS.BLACK, bottom: p.y === -1.5 ? CUBE_COLORS.ORANGE : CUBE_COLORS.BLACK, front: p.z === 1.5 ? CUBE_COLORS.WHITE : CUBE_COLORS.BLACK, back: p.z === -1.5 ? CUBE_COLORS.RED : CUBE_COLORS.BLACK };
        const mats = ['right', 'left', 'top', 'bottom', 'front', 'back'].map(f => new THREE.MeshStandardMaterial({ color: fc[f] }));
        const cubie = new THREE.Mesh(new THREE.BoxGeometry(size, size, size), mats);
        cubie.position.set(p.x * (size + spacing), p.y * (size + spacing), p.z * (size + spacing));
        cubie.userData = { originalPosition: new THREE.Vector3(p.x, p.y, p.z), faceColors: fc };
        rubikCube.add(cubie);
        allCubies.push(cubie); 
    }
    scene.add(rubikCube);
}

function rotateFace(move, isClockwise) {
    if (isAnimating) { rotationQueue.push({ move, isClockwise }); return; }
    isAnimating = true;
    const config = CUBE_MOVES[move];
    const axis = new THREE.Vector3(config.axis === 'x' ? 1 : 0, config.axis === 'y' ? 1 : 0, config.axis === 'z' ? 1 : 0);
    const angle = (Math.PI / 2) * config.sign * (isClockwise ? 1 : -1);
    const cubies = rubikCube.children.filter(c => config.layers.some(layer => Math.abs(c.userData.originalPosition[config.axis] - layer) < 0.1));
    const group = new THREE.Group();
    scene.add(group);
    cubies.forEach(c => group.attach(c));
    currentAnimation = { group, axis, targetAngle: angle, currentAngle: 0,
        onComplete: () => {
            group.quaternion.setFromAxisAngle(axis, angle);
            cubies.forEach(c => rubikCube.attach(c));
            scene.remove(group);
            const rotMat = new THREE.Matrix4().makeRotationAxis(axis, angle);
            cubies.forEach(c => {
                const p = c.userData.originalPosition;
                p.applyMatrix4(rotMat);
                p.x = Math.round(p.x * 2) / 2; p.y = Math.round(p.y * 2) / 2; p.z = Math.round(p.z * 2) / 2;
            });
            isAnimating = false;
            currentAnimation = null;
            (rotationQueue.length > 0) ? rotateFace(...Object.values(rotationQueue.shift())) : onInteractionEnd();
        }
    };
}

function onInteractionEnd() { getFrontFaceStickers(); if (isPlaying) startSequencer(); }

function getFrontFaceStickers() {
    const viewDir = new THREE.Vector3();
    camera.getWorldDirection(viewDir).negate();
    const camUp = new THREE.Vector3().copy(camera.up).applyQuaternion(camera.quaternion);
    const camRight = new THREE.Vector3().crossVectors(viewDir, camUp).normalize();
    let visible = [];
    rubikCube.children.forEach(cubie => {
        const normalMatrix = new THREE.Matrix3().getNormalMatrix(cubie.matrixWorld);
        Object.entries(cubie.userData.faceColors).forEach(([name, color]) => {
            if (color === CUBE_COLORS.BLACK) return;
            const worldNormal = getNormalForFace(name).clone().applyMatrix3(normalMatrix).normalize();
            if (worldNormal.dot(viewDir) > 0.5) visible.push({ cubie, color, dot: worldNormal.dot(viewDir), faceName: name });
        });
    });
    visible.sort((a, b) => b.dot - a.dot);
    const front = visible.slice(0, 16);
    if (front.length < 16) return;
    front.sort((a, b) => {
        const pA = new THREE.Vector3().setFromMatrixPosition(a.cubie.matrixWorld), pB = new THREE.Vector3().setFromMatrixPosition(b.cubie.matrixWorld);
        const yA = pA.dot(camUp), yB = pB.dot(camUp);
        return Math.abs(yA - yB) > 0.1 ? yB - yA : pA.dot(camRight) - pB.dot(camRight);
    });
    currentFrontFaceStickers = front;
    updateAllMuteVisuals();
}

function handleTouchStart(event) {
    // Record the starting time and position of the touch
    touchStartTime = Date.now();
    isDragging = false;
    const touch = event.touches[0];
    touchStartX = touch.clientX;
    touchStartY = touch.clientY;
}

function handleTouchMove(event) {
    if (isDragging) return; // If we already know it's a drag, no need to check again.
    
    const touch = event.touches[0];
    const deltaX = Math.abs(touch.clientX - touchStartX);
    const deltaY = Math.abs(touch.clientY - touchStartY);

    // INCREASED: The drag threshold is now more generous (10 pixels instead of 5).
    if (deltaX > 10 || deltaY > 10) {
        isDragging = true;
    }
}

function handleTouchEnd(event) {
    // Calculate the total duration of the touch
    const touchDuration = Date.now() - touchStartTime;

    // A valid "tap" must meet TWO conditions:
    // 1. It was NOT a drag (the finger didn't move far).
    // 2. It was very QUICK (less than 250 milliseconds).
    if (!isDragging && touchDuration < 250) {
        // If both conditions are met, treat it as a tap/click.
        handleCanvasClick(event.changedTouches[0]);
    }
    
    // Reset the dragging flag for the next interaction.
    isDragging = false;
}


function handleCanvasClick(event) {
    const mouse = new THREE.Vector2((event.clientX / renderer.domElement.clientWidth) * 2 - 1, -(event.clientY / renderer.domElement.clientHeight) * 2 + 1);
    const raycaster = new THREE.Raycaster();
    raycaster.setFromCamera(mouse, camera);
    const intersects = raycaster.intersectObjects(rubikCube.children);
    if (intersects.length > 0) {
        const { object: cubie, face } = intersects[0];
        const faceName = getFaceNameFromMaterialIndex(face.materialIndex);
        if (!faceName) return;
        const { x, y, z } = cubie.userData.originalPosition;
        const stickerId = `x:${x},y:${y},z:${z}_face:${faceName}`;
        mutedStickers.has(stickerId) ? mutedStickers.delete(stickerId) : mutedStickers.add(stickerId);
        applyMuteVisual(cubie, faceName, mutedStickers.has(stickerId));
        if (isPlaying) startSequencer();
    }
}

function applyMuteVisual(cubie, faceName, isMuted) {
    const matIndex = getMaterialIndexForFace(faceName);
    if (matIndex === -1) return;
    const mat = cubie.material[matIndex];
    mat.color.setHex(cubie.userData.faceColors[faceName]);
    if (isMuted) mat.color.multiplyScalar(0.4);
}

function updateAllMuteVisuals() {
    rubikCube.children.forEach(c => Object.entries(c.userData.faceColors).forEach(([name, color]) => {
        if (color === CUBE_COLORS.BLACK) return;
        const { x, y, z } = c.userData.originalPosition;
        const id = `x:${x},y:${y},z:${z}_face:${name}`;
        applyMuteVisual(c, name, mutedStickers.has(id));
    }));
}

function scrambleCube() {
    if (isAnimating) return;
    let lastAxis = '', moves = [];
    const moveKeys = Object.keys(CUBE_MOVES);
    for (let i = 0; i < 30; i++) {
        const available = moveKeys.filter(m => CUBE_MOVES[m].axis !== lastAxis);
        const move = available[Math.floor(Math.random() * available.length)];
        moves.push({ move, isClockwise: Math.random() > 0.5 });
        lastAxis = CUBE_MOVES[move].axis;
    }
    moves.forEach(m => rotateFace(m.move, m.isClockwise));
}

function onWindowResize() { const c = document.getElementById('container'); camera.aspect = c.clientWidth / c.clientHeight; camera.updateProjectionMatrix(); renderer.setSize(c.clientWidth, c.clientHeight); }
function getMaterialIndexForFace(name) { return ['right', 'left', 'top', 'bottom', 'front', 'back'].indexOf(name); }
function getFaceNameFromMaterialIndex(index) { return ['right', 'left', 'top', 'bottom', 'front', 'back'][index]; }
function getNormalForFace(name) { const n = { right: [1, 0, 0], left: [-1, 0, 0], top: [0, 1, 0], bottom: [0, -1, 0], front: [0, 0, 1], back: [0, 0, -1] }; return new THREE.Vector3(...(n[name] || [0, 0, 0])); }

// --- Let's Go! ---
init();
animate();
