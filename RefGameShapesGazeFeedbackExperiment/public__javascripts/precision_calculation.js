/*
 * This function calculates a measurement for how precise 
 * the eye tracker currently is which is displayed to the user
 */
function calculatePrecision(past50Array, staringPointX, staringPointY, x_w, y_w) {
    var windowHeight = window.innerHeight;
    var windowWidth = window.innerWidth;
    
    // Retrieve the last 50 gaze prediction points
    var x50 = past50Array[0];
    var y50 = past50Array[1];
  
    var precisionPercentages = new Array(50);
    calculatePrecisionPercentages(precisionPercentages, windowHeight, x50, y50, staringPointX, staringPointY, x_w, y_w);
    var precision = calculateAverage(precisionPercentages);
  
    // Return the precision measurement as a rounded percentage
    return Math.round(precision);
  };
  
  /*
   * Calculate percentage accuracy for each prediction based on distance of
   * the prediction point from the centre point (uses the window height as
   * lower threshold 0%)
   */
  function calculatePrecisionPercentages(precisionPercentages, windowHeight, x50, y50, staringPointX, staringPointY, x_w, y_w) {
    for (x = 0; x < 50; x++) {
      // Calculate distance between each prediction and staring point
      var xDiff = x_w * (staringPointX - x50[x]);
      var yDiff = y_w * (staringPointY - y50[x]);
      var distance = Math.sqrt((xDiff * xDiff) + (yDiff * yDiff));
  
      // Calculate precision percentage
      var halfWindowHeight = windowHeight / 2;
      var precision = 0;
      if (distance <= halfWindowHeight && distance > -1) {
        precision = 100 - (distance / halfWindowHeight * 100);
      } else if (distance > halfWindowHeight) {
        precision = 0;
      } else if (distance > -1) {
        precision = 100;
      }
  
      // Store the precision
      precisionPercentages[x] = precision;
    }
  }
  
  /*
   * Calculates the average of all precision percentages calculated
   */
  function calculateAverage(precisionPercentages) {
    var precision = 0;
    for (x = 0; x < 50; x++) {
      precision += precisionPercentages[x];
    }
    precision = precision / 50;
    return precision;
  }

/*
 * Sets store_points to true, so all the occuring prediction
 * points are stored
 */
function store_points_variable(){
    webgazer.params.storingPoints = true;
}
  
/*
* Sets store_points to false, so prediction points aren't
* stored any more
*/
function stop_storing_points_variable(){
    webgazer.params.storingPoints = false;
}