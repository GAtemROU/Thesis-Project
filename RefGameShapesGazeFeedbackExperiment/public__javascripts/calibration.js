var pointCalibrate = 0;
var calibrationPoints={};
var callback = null;

let requiredAccuracy = 65;
let allowSkipCalibration = false;
let simplifiedCalibration = false; // only set to true during testing, the calibration is not accurate enough when set to true
let clicksPerPoint = simplifiedCalibration ? 1 : 5;
let totalPoints = simplifiedCalibration ? 1 : 11;
let accuracyCheckDuration = simplifiedCalibration ? 1 : 5000;


// Find the help modal
var helpModal;
/**
 * Clear the canvas and the calibration button.
 */
function clearCanvas(){
  document.querySelectorAll('.Calibration').forEach((i) => {
    i.style.setProperty('display', 'none');
  });
  var canvas = document.getElementById("plotting_canvas");
  canvas.getContext('2d').clearRect(0, 0, canvas.width, canvas.height);
}
function removeCanvas(){
  var canvas = document.getElementById("plotting_canvas");
  canvas.style.setProperty('display', 'none');
}

/**
 * Show the instruction of using calibration at the start up screen.
 */
function PopUpInstruction(){
  swal({
    title:"Calibration",
    text: "Now we will do the calibration procedure. We will not store any video of you directly, only the estimated coordinates of your eye gaze. Make sure your face is located in the center of the video in the upper left corner. \n\nPlease click on each of the 11 points on the screen. You must click on each point 5 times till it goes yellow. This will calibrate your eye movements.",
    buttons:{
      cancel: false,
      confirm: true
    }
  }).then(isConfirm => {
    ShowCalibrationPoints();
  });
}

async function calcAccuracy(points) {
    // show modal
    // notification for the measurement process
    for (let i = 0; i < points.length; i++) {
    document.getElementById("PtAcc" + points[i].name).style.removeProperty('display');
    await swal({
        title: "Calculating measurement",
        text: `Please don't move your mouse & stare at the ${points[i].name} dot for the next 5 seconds. This will allow us to calculate the accuracy of our predictions.`,
        closeOnEsc: false,
        allowOutsideClick: false,
        closeModal: true  
    }).then(async () => {
        // makes the variables true for 5 seconds & plots the points
        var windowHeight = window.innerHeight;
        var windowWidth = window.innerWidth;
        // Calculate the position of the point the user is staring at
        store_points_variable(); // start storing the prediction points
        await sleep(accuracyCheckDuration).then(async () => {
                stop_storing_points_variable(); // stop storing the prediction points
                var past50 = webgazer.getStoredPoints(); // retrieve the stored points
                var precision_measurement = calculatePrecision(past50, points[i].x, points[i].y);
                if (precision_measurement < requiredAccuracy) {
                  await swal({
                    title: `Your accuracy measure is ${precision_measurement}%`,
                    text: "Unfortunately, it is too low to continue, the desired accuracy is at least 65%. Please consider adjusting your setup and redo the calibration.",
                    allowOutsideClick: false,
                    buttons: allowSkipCalibration ?{
                      confirm: "Recalibrate",
                      cancel: "skip"
                    } : {
                      confirm: "Recalibrate"
                    }
                  }).then(isConfirm => {
                    if (isConfirm) {
                      //use restart function to restart the calibration
                      webgazer.clearData();
                      ClearCalibration();
                      clearCanvas();
                      ShowCalibrationPoints();
                      i = points.length;
                    } else {
                      clearCanvas();
                      //webgazer.showPredictionPoints(false);
                      document.getElementById("PtAcc" + points[i].name).style.setProperty('display', 'none');
                      if (i == points.length - 1) {
                        stopResizing();
                        removeCanvas();
                        document.getElementById('calibration_next').style.setProperty('visibility', 'visible');
                      }
                    }
                  });
                } else {
                  await swal({
                      title: `Your accuracy measure is ${precision_measurement}%`,
                      text: "This is satisfiable. " + (i == points.length-1) ? "You can continue with the experiment.": "We will now move to the next point.",
                      allowOutsideClick: false,
                      buttons: {
                        cancel: "Recalibrate",
                        confirm: true
                      }
                  }).then(isConfirm => {
                          if (isConfirm){
                              //clear the calibration & hide the current accuracy check button
                              clearCanvas();
                              //webgazer.showPredictionPoints(false);
                              document.getElementById("PtAcc" + points[i].name).style.setProperty('display', 'none');
                              if (i == points.length - 1) {
                                stopResizing();
                                removeCanvas();
                                document.getElementById('calibration_next').style.setProperty('visibility', 'visible');
                              }
                            } else {
                              //use restart function to restart the calibration
                              webgazer.clearData();
                              ClearCalibration();
                              clearCanvas();
                              ShowCalibrationPoints();
                              i = points.length;
                          }
                  });
                }
        });
    });
  }
}

function calPointClick(node) {
    const id = node.id;

    if (!calibrationPoints[id]){ // initialises if not done
        calibrationPoints[id]=0;
    }
    calibrationPoints[id]++; // increments values

    if (calibrationPoints[id]==clicksPerPoint){ //only turn to yellow after 5 clicks
        node.style.setProperty('background-color', 'yellow');
        node.setAttribute('disabled', 'disabled');
        pointCalibrate++;
    }else if (calibrationPoints[id]<5){
        //Gradually increase the opacity of calibration points when click to give some indication to user.
        var opacity = 0.2*calibrationPoints[id]+0.2;
        node.style.setProperty('opacity', opacity);
    }

    //Show the middle calibration point after all other points have been clicked.
    if (pointCalibrate == totalPoints-1){
        document.getElementById('PtAccMiddle').style.removeProperty('display');
    }

    if (pointCalibrate >= totalPoints){ // last point is calibrated
        // grab every element in Calibration class and hide them except the middle point.
        document.querySelectorAll('.Calibration').forEach((i) => {
            i.style.setProperty('display', 'none');
        });
        document.getElementById('PtAccMiddle').style.removeProperty('display');

        // clears the canvas
        var canvas = document.getElementById("plotting_canvas");
        canvas.getContext('2d').clearRect(0, 0, canvas.width, canvas.height);

        points = [{"name" : "Middle", "x": window.innerWidth / 2, "y": window.innerHeight / 2},
                  {"name" : "Left",   "x": window.innerWidth / 5, "y": window.innerHeight / 2},
                  {"name" : "Right",  "x": window.innerWidth * 4 / 5, "y": window.innerHeight / 2}];
        // Calculate the accuracy
        if (simplifiedCalibration) {
          points = [{"name" : "Middle", "x": window.innerWidth / 2, "y": window.innerHeight / 2}];
        }
        calcAccuracy(points);
    }
}


function calibrate(callback_f) {
  startResizing();
  clearCanvas();
  PopUpInstruction();
  // click event on the calibration buttons
  document.querySelectorAll('.Calibration').forEach((i) => {
      i.addEventListener('click', () => {
          calPointClick(i);
      })
  })
  callback = callback_f;
};

/**
 * Show the Calibration Points
 */
function ShowCalibrationPoints() {
  document.querySelectorAll('.Calibration').forEach((i) => {
    i.style.removeProperty('display');
  });
  // initially hides the middle button
  document.getElementById('PtAccMiddle').style.setProperty('display', 'none');
}

/**
* This function clears the calibration buttons memory
*/
function ClearCalibration(){
  // Clear data from WebGazer

  document.querySelectorAll('.Calibration').forEach((i) => {
    i.style.setProperty('background-color', 'red');
    i.style.setProperty('opacity', '0.2');
    i.removeAttribute('disabled');
  });

  calibrationPoints = {};
  pointCalibrate = 0;
}

// sleep function because java doesn't have one, sourced from http://stackoverflow.com/questions/951021/what-is-the-javascript-version-of-sleep
function sleep (time) {
  return new Promise((resolve) => setTimeout(resolve, time));
}