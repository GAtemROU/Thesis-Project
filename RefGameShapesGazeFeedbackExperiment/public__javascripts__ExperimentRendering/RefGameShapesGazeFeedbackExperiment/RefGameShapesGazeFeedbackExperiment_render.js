(function () {
    var app = angular.module('RefGameShapesGazeFeedbackExperimentApp', ["Lingoturk"]);

    app.controller('RenderController', ['$http', '$timeout', '$scope', function ($http, $timeout, $scope) {
        var self = this;
        self.state = "";
        self.allStates = [];
        self.questions = [];
        self.part = null;
        self.slideIndex = 0;
        self.questionIndex = 0;
        self.expId = null;
        self.questionId = null;
        self.partId = null;
        self.origin = null;
        self.hitId = "";
        self.assignmentId = "";
        self.workerId = "";
        self.subListMap = {};
        self.subListsIds = [];
        self.showMessage = "none";
        self.redirectUrl = null;
        self.IsEnabled = true;
        self.curGazeData = {};
        self.gazeData = [];
        self.itemPositions = [];

        self.shuffleQuestions = true;
        self.shuffleSublists = true;
        self.useGoodByeMessage = true;
        self.useStatistics = true;

        self.strategyQuestionIndex = 0;
        self.practiceQuestionIndex = 0;

        self.trialStartTime = null;


        self.practiceQuestions = [
        {img1: "sq_re", img2: "ci_gr", img3: "tr_bl_target", text: "Imagine you have to get someone to pick out the highlighted object by sending only one of the following four messages."},
        {img1: "tr_bl", img2: "ci_re_target", img3: "tr_gr", text: "What you just did was the previous participant's task. Let's do another one."},
        {img1: "tr_gr_target", img2: "tr_gr", img3: "ci_re", text: "Great! Let's do another one."},
        {img1: "ci_bl", img2: "sq_gr_target", img3: "tr_re", text: "Great! Here's one more."},
        ];


        self.SurveyStatistics = [
            {name : "What do you think this experiment was about?", answer : "", type: "text", answer : ""},
            {name : "How enjoyable did you find the task, on a scale from 1 to 5?", type: "number", answer : undefined},
            {name : "Did you experience any technical difficulties or interruptions during this task?", answer : "", type: "text", answer : "", optional : true},
            {name : "Do you have any other questions or comments for the researcher about this task? If so, please type them here.", type : "text", answer : "", optional : true},

        ];

        // need to change text fields for this - add type
        // can do tmrw -- for today can just hand-pick one complex and one simple
        // self.simpleStrategyFinal = null;
        // self.compexStrategyFinal = null;
        self.strategyQuestions = [];
        // dummies for now, change later
        self.strategyIds = ["2","3"];


        this.resultsSubmitted = function(){
            self.subListsIds.splice(0,1);
            if(self.subListsIds.length > 0 ){
                self.showMessage = "nextSubList";
            }else{
                self.processFinish();
            }
        };

        this.processFinish = function(){
            if(!self.useGoodByeMessage){
                self.finished();
            }else{
                self.showMessage = "goodBye";
            }
        };

        this.finished = function(){
            if(self.origin == null || self.origin == "NOT AVAILABLE"){
                bootbox.alert("Results successfully submitted. You might consider redirecting your participants now.");
            }else if(self.origin == "MTURK"){
                $("#form").submit();
            }else if(self.origin == "PROLIFIC"){
                if(inIframe()){
                    window.top.location.href = self.redirectUrl;
                }else{
                    window.location = self.redirectUrl;
                }
            }
        };

        this.prepareQuestions = function(){
            // shuffling the order of img1, img2, img3
            // console.log(self.questions.length);
            for (var i = 0; i < self.questions.length; ++i){
                var question = self.questions[i];
                const target = question.img1;

                var temp_array = [question.img1, question.img2, question.img3];
                shuffleArray(temp_array);

                question.answer = {};
                question.answer['presOrder'] = temp_array;
                question.answer['targetPos'] = temp_array.indexOf(target);

                question.img1 = temp_array[0];
                question.img2 = temp_array[1];
                question.img3 = temp_array[2];
            }

            // console.log(self.questions);

        };

        this.startTimer = function(){
            self.trialStartTime = Date.now();
        };

        this.nextPrepQuestions = function(){
            self.prepareQuestions();
            self.next();

        };

        this.nextSublist = function(){
            self.questionIndex = 0;
            self.questions = self.subListMap[self.subListsIds[0]];
            self.showMessage = "none";
        };

        this.resultSubmissionError = function(){
            self.failedTries = 0;
            bootbox.alert("An error occurred while submitting your results. Please try again in a few seconds.");
        };

        this.handleError = function(){
            if(self.failedTries < 100){
                ++self.failedTries;
                setTimeout(function() { self.submitResults(self.resultsSubmitted, self.handleError) }, 1000);
            }else{
                self.resultSubmissionError();
            }
        };

        self.failedTries = 0;
        this.submitResults = function (successCallback, errorCallback) {
            var results = {
                experimentType : "RefGameShapesGazeFeedbackExperiment",
                results : self.questions,
                expId : self.expId,
                origin : self.origin,
                statistics : self.SurveyStatistics,
                assignmentId : self.assignmentId,
                hitId : self.hitId,
                workerId : self.workerId,
                partId : (self.partId == null ? -1 : self.partId),
                gaze : self.gazeData,
                itemPositions : self.itemPositions
            };


            $http.post("/submitResults", results)
                .success(successCallback)
                .error(errorCallback);
        };

        this.next = function(){
            if(self.state == "workerIdSlide"){
                if(self.questionId == null && self.partId == null){
                    self.load(function(){
                        self.state = self.allStates[++self.slideIndex];
                    });
                    return;
                }
            }

            if(self.slideIndex + 1 < self.allStates.length){
                self.state = self.allStates[++self.slideIndex];
                if (self.state == "generalQuestionsSlide"){
                    webgazer.end();
                }
            }else{
                self.submitResults(self.resultsSubmitted, self.handleError);
            }
        };

        this.findPos = function findPos(obj) {
            var curleft = curtop = 0;
            if (obj.offsetParent) {
                do {
                    curleft += obj.offsetLeft;
                    curtop += obj.offsetTop;
                } while (obj = obj.offsetParent);
                return { x: curleft, y: curtop };
            }
        }

        this.savePositions = function(){
            var positions = {};
            positions['msg_sent'] = self.findPos(document.getElementById('msg_sent'));
            for (let i = 1; i < 4; i++){
                positions['img'+i] = self.findPos(document.getElementById('img'+i));
            }
            let msgs = ['ci','tr','gr','re'];
            for (let i = 0; i < 4; i++){
                positions['msg_'+msgs[i]] = self.findPos(document.getElementById('msg_'+msgs[i]));
            }
            this.itemPositions.push(positions);
        }

        this.nextQuestion = function(ans){
            webgazer.pause();
            var question = self.questions[self.questionIndex];
            question.answer['answerTime'] = Date.now() - self.trialStartTime;
            question.answer['trialId'] = self.questionIndex+1;
            question.answer['choicePos'] = ans;
            question.answer['choice'] = question.answer['presOrder'][ans];
            self.gazeData.push(self.curGazeData);
            self.curGazeData = {};

            var content = document.getElementById('question_slide_content');

            // console.log('comparing correctness',question.answer['choicePos'],question.answer['targetPos']);

            if (question.answer['choicePos'] == question.answer['targetPos']){
                question.answer['correct'] = 1;
                var feedback = document.getElementById('feedback_correct');
            }
            else{
                question.answer['correct'] = 0;
                var feedback = document.getElementById('feedback_incorrect');
            }
            // console.log(question.answer['correct']);

            content.style.display = 'none';
            feedback.style.display = 'flex';
            $timeout(function () {
                if(self.questionIndex + 1 < self.questions.length){
                    content.style.display = 'flex';
                    feedback.style.display = 'none';
                    ++self.questionIndex;
                    webgazer.resume();
                }else{
                    self.SIs = self.questions.filter(obj => obj.itemid === "4");
                    self.CIs = self.questions.filter(obj => obj.itemid === "13");

                    var SI = self.SIs[0];
                    var CI = self.CIs[0];
                    self.strategyQuestions = [SI, CI];

                    self.next();
                }

            }, 1200);   
        };


        this.revealStrategyBox = function(ans){
            var question = self.strategyQuestions[self.strategyQuestionIndex];
            question.answer['secondAnswer'] = ans;
            question.answer['secondResponseTime'] = Date.now() - self.trialStartTime;

            // document.getElementById("strategyTable").visibility = 'hidden';
            document.getElementById('img'+ans.slice(-1)).style.border = '2px solid red'; 
            self.IsEnabled = false;

        };

        this.nextStrategyQuestion = function(){
            if(self.strategyQuestionIndex + 1 < self.strategyQuestions.length){
                ++self.strategyQuestionIndex;
                self.IsEnabled = true;
            }else{
                self.next();
            }

        };

        this.nextPracticeQuestion = function(ans){
            var question = self.practiceQuestions[self.practiceQuestionIndex];
            question.answer = {};
            question.answer.choice = ans;

            if(self.practiceQuestionIndex + 1 < self.practiceQuestions.length){
                ++self.practiceQuestionIndex;
            }else{
                self.next();
            }
        };
        

        this.load = function(callback){
            var subListMap = self.subListMap;

            if(self.questionId != null){
                $http.get("/getQuestion/" + self.questionId).success(function (data) {
                    self.questions = [data];

                    subListMap[self.questions[0].subList] = [self.questions[0]];

                    if(callback !== undefined){
                        callback();
                    }
                });
            }else if(self.partId != null){
                $http.get("/returnPart?partId=" + self.partId).success(function (data) {
                    var json = data;
                    self.part = json;
                    self.questions = json.questions;

                    if(self.shuffleQuestions){
                        shuffleArray(self.part.questions);
                    }

                    for(var i = 0; i < self.questions.length; ++i){
                        var q = self.questions[i];
                        if (subListMap.hasOwnProperty(q.subList)){
                            subListMap[q.subList].push(q);
                        }else{
                            subListMap[q.subList] = [q];
                            self.subListsIds.push(q.subList);
                        }
                    }
                    if(self.shuffleSublists){
                        shuffleArray(self.subListsIds);
                    }
                    self.questions = self.subListMap[self.subListsIds[0]];

                    if(callback !== undefined){
                        callback();
                    }
                });
            }else{
                $http.get("/getPart?expId=" + self.expId + "&workerId=" + self.workerId).success(function (data) {
                    var json = data;
                    self.part = json;
                    self.partId = json.id;
                    self.questions = json.questions;

                    if(self.shuffleQuestions){
                        shuffleArray(self.part.questions);
                    }

                    for(var i = 0; i < self.questions.length; ++i){
                        var q = self.questions[i];
                        if (subListMap.hasOwnProperty(q.subList)){
                            subListMap[q.subList].push(q);
                        }else{
                            subListMap[q.subList] = [q];
                            self.subListsIds.push(q.subList);
                        }
                    }
                    if(self.shuffleSublists){
                        shuffleArray(self.subListsIds);
                    }
                    self.questions = self.subListMap[self.subListsIds[0]];

                    if(callback !== undefined){
                        callback();
                    }
                });
            }

        };

        this.startCalibration = function(){
            //start the webgazer tracker
            webgazer.setRegression('ridge') /* currently must set regression and tracker */
                // .setTracker('TFFacemesh')
                .setGazeListener(function(data, clock) {
                    self.curGazeData[clock-self.trialStartTime] = data;
                })
                .saveDataAcrossSessions(false)
                .begin();
                webgazer.showVideoPreview(true) /* shows all video previews */
                    .showPredictionPoints(true) /* shows a square every 100 milliseconds where current prediction is */
                    .applyKalmanFilter(true);

            //Set up the webgazer video feedback.
            var setup = function() {

                //Set up the main canvas. The main canvas is used to calibrate the webgazer.
                var canvas = document.getElementById("plotting_canvas");
                canvas.width = window.innerWidth;
                canvas.height = window.innerHeight;
                canvas.style.position = 'fixed';
            };
            setup();
            calibrate(self.next);
        }

        

        $(document).ready(function () {
            self.questionId = ($("#questionId").length > 0) ? $("#questionId").val() : null;
            self.partId = ($("#partId").length > 0) ? $("#partId").val() : null;
            self.expId = ($("#expId").length > 0) ? $("#expId").val() : null;
            self.hitId = ($("#hitId").length > 0) ? $("#hitId").val() : "NOT AVAILABLE";
            self.workerId = ($("#workerId").length > 0) ? $("#workerId").val() : "";
            self.assignmentId = ($("#assignmentId").length > 0) ? $("#assignmentId").val() : "NOT AVAILABLE";
            self.origin = ($("#origin").length > 0) ? $("#origin").val() : "NOT AVAILABLE";
            self.redirectUrl = ($("#redirectUrl").length > 0) ? $("#redirectUrl").val() : null;

            if(self.questionId != null || self.partId != null){
                self.load();
            }

            self.allStates = ["instructionsSlide","workerIdSlide","specificInstructionsSlide","calibrationSlide","practiceQuestionSlide","experimentStartSlide","questionSlide","strategySlide","generalQuestionsSlide"];


            if(!self.useStatistics){
                var index = self.allStates.indexOf("statisticsSlide");
                self.allStates.splice(index,1);
            }

            if(self.workerId.trim() != ""){
                var index = self.allStates.indexOf("workerIdSlide");
                self.allStates.splice(index,1);
            }

            $scope.$apply(self.state = self.allStates[0]);

            $(document).on("keypress", ":input:not(textarea)", function(event) {
                if (event.keyCode == 13) {
                    event.preventDefault();
                }
            });
        });
    }]);
})();


