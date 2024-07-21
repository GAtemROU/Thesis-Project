/**
* This function occurs on resizing the frame
* clears the canvas & then resizes it (as plots have moved position, can't resize without clear)
*/
function startResizing() {
    window.addEventListener('resize', resize, false);
}

function stopResizing() {
    window.removeEventListener('resize', resize, false);
}

function resize() {
    var canvas = document.getElementById('plotting_canvas');
    var context = canvas.getContext('2d');
    context.clearRect(0, 0, canvas.width, canvas.height);
    canvas.width = window.innerWidth;
    canvas.height = window.innerHeight;
};