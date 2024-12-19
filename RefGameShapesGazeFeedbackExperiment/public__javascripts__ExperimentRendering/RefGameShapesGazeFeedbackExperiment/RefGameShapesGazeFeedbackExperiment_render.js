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

        self.device_info = {};
        
        self.curGazeData = {};
        self.itemCoordinates = {};

        self.shuffleQuestions = true;
        self.shuffleSublists = true;
        self.useGoodByeMessage = true;
        self.useStatistics = true;

        self.strategyQuestionsLength = 2;
        self.strategyQuestionIndex = 0;
        self.practiceQuestionIndex = 0;

        self.experimentStartTime = null;
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

        self.strategyQuestions = [];

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
            for (var i = 0; i < self.questions.length; ++i){
                let question = self.questions[i];
                var objects = [question.trgt, question.comp, question.dist];
                var msgs = [question.msg1, question.msg2, question.msg3, question.msg4];
                shuffleArray(objects);
                shuffleArray(msgs);
                let trial = {
                    sent_msg: question.sent_msg,
                    trgtPos: objects.indexOf(question.trgt),
                    objects: objects,
                    img1 : objects[0],
                    img2 : objects[1],
                    img3 : objects[2],
                    msg1 : msgs[0],
                    msg2 : msgs[1],
                    msg3 : msgs[2],
                    msg4 : msgs[3],
                };
                question.answer = {};
                question.answer['userTrialId'] = i+1;
                question.answer['sent_msg'] = question.sent_msg;
                question.answer['objs'] = trial.objects;
                question.answer['trgtPos'] = objects.indexOf(question.trgt);
                question.answer['compPos'] = objects.indexOf(question.comp);
                question.answer['distPos'] = objects.indexOf(question.dist);
                question.answer['type'] = question.type;
                question.answer['msgsOrder'] = msgs;

                question['trial'] = trial;
            }

            // take out the last two questions for the strategy trials
            self.strategyQuestions = self.questions.splice(self.questions.length - self.strategyQuestionsLength, self.strategyQuestionsLength);
            
            if (self.shuffleQuestions) {
                shuffleArray(self.questions);
            }
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
                };


            $http.post("/submitResults", results)
                .success(successCallback)
                .error(errorCallback);
        };

        this.next = function(){
            // console.log(navigator.userAgent);
            if(self.state == "workerIdSlide"){
                if(self.questionId == null && self.partId == null){
                    self.load(function(){
                        self.state = self.allStates[++self.slideIndex];
                    });
                    return;
                }
            }
            if(self.state == "calibrationSlide") {
                self.startTimer();
                self.curGazeData = {};
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

        this.findPos = function (obj) {
            var curleft = curtop = 0;
            do {
                curleft += obj.offsetLeft;
                curtop += obj.offsetTop;
                obj = obj.offsetParent
            } while (obj);
            return { x: curleft, y: curtop };
        }

        this.savePositions = function(){
            var positions = {};
            positions['sent_msg'] = self.findPos(document.getElementById('sent_msg_img'));
            let img = document.getElementById('sent_msg_img');
            positions['sent_msg']['width'] = img.offsetWidth;
            positions['sent_msg']['height'] = img.offsetHeight;
            for (let i = 1; i < 4; i++){
                positions['img'+i] = self.findPos(document.getElementById('img'+i));
                positions['img'+i]['width'] = document.getElementById('img'+i).offsetWidth;
                positions['img'+i]['height'] = document.getElementById('img'+i).offsetHeight;
            }
            for (let i = 0; i < 4; i++){
                positions['msg'+String(i+1)] = self.findPos(document.getElementById('msg'+String(i+1)));
                positions['msg'+String(i+1)]['width'] = document.getElementById('msg'+String(i+1)).offsetWidth;
                positions['msg'+String(i+1)]['height'] = document.getElementById('msg'+String(i+1)).offsetHeight;
            }
            return positions;
        }

        /**
         * JavaScript Client Detection
         * (C) viazenetti GmbH (Christian Ludwig)
         */
        this.save_device_info = function(window) {
            {
                var unknown = '-';
                
                // screen
                var screenSize = '';
                if (screen.width) {
                    width = (screen.width) ? screen.width : '';
                    height = (screen.height) ? screen.height : '';
                    screenSize += '' + width + " x " + height;
                }

                // browser
                var nVer = navigator.appVersion;
                var nAgt = navigator.userAgent;
                var browser = navigator.appName;
                var version = '' + parseFloat(nVer);
                var nameOffset, verOffset, ix;
        
                // Yandex Browser
                if ((verOffset = nAgt.indexOf('YaBrowser')) != -1) {
                    browser = 'Yandex';
                    version = nAgt.substring(verOffset + 10);
                }
                // Samsung Browser
                else if ((verOffset = nAgt.indexOf('SamsungBrowser')) != -1) {
                    browser = 'Samsung';
                    version = nAgt.substring(verOffset + 15);
                }
                // UC Browser
                else if ((verOffset = nAgt.indexOf('UCBrowser')) != -1) {
                    browser = 'UC Browser';
                    version = nAgt.substring(verOffset + 10);
                }
                // Opera Next
                else if ((verOffset = nAgt.indexOf('OPR')) != -1) {
                    browser = 'Opera';
                    version = nAgt.substring(verOffset + 4);
                }
                // Opera
                else if ((verOffset = nAgt.indexOf('Opera')) != -1) {
                    browser = 'Opera';
                    version = nAgt.substring(verOffset + 6);
                    if ((verOffset = nAgt.indexOf('Version')) != -1) {
                        version = nAgt.substring(verOffset + 8);
                    }
                }
                // Legacy Edge
                else if ((verOffset = nAgt.indexOf('Edge')) != -1) {
                    browser = 'Microsoft Legacy Edge';
                    version = nAgt.substring(verOffset + 5);
                } 
                // Edge (Chromium)
                else if ((verOffset = nAgt.indexOf('Edg')) != -1) {
                    browser = 'Microsoft Edge';
                    version = nAgt.substring(verOffset + 4);
                }
                // MSIE
                else if ((verOffset = nAgt.indexOf('MSIE')) != -1) {
                    browser = 'Microsoft Internet Explorer';
                    version = nAgt.substring(verOffset + 5);
                }
                // Chrome
                else if ((verOffset = nAgt.indexOf('Chrome')) != -1) {
                    browser = 'Chrome';
                    version = nAgt.substring(verOffset + 7);
                }
                // Safari
                else if ((verOffset = nAgt.indexOf('Safari')) != -1) {
                    browser = 'Safari';
                    version = nAgt.substring(verOffset + 7);
                    if ((verOffset = nAgt.indexOf('Version')) != -1) {
                        version = nAgt.substring(verOffset + 8);
                    }
                }
                // Firefox
                else if ((verOffset = nAgt.indexOf('Firefox')) != -1) {
                    browser = 'Firefox';
                    version = nAgt.substring(verOffset + 8);
                }
                // MSIE 11+
                else if (nAgt.indexOf('Trident/') != -1) {
                    browser = 'Microsoft Internet Explorer';
                    version = nAgt.substring(nAgt.indexOf('rv:') + 3);
                }
                // Other browsers
                else if ((nameOffset = nAgt.lastIndexOf(' ') + 1) < (verOffset = nAgt.lastIndexOf('/'))) {
                    browser = nAgt.substring(nameOffset, verOffset);
                    version = nAgt.substring(verOffset + 1);
                    if (browser.toLowerCase() == browser.toUpperCase()) {
                        browser = navigator.appName;
                    }
                }
                // trim the version string
                if ((ix = version.indexOf(';')) != -1) version = version.substring(0, ix);
                if ((ix = version.indexOf(' ')) != -1) version = version.substring(0, ix);
                if ((ix = version.indexOf(')')) != -1) version = version.substring(0, ix);
        
                majorVersion = parseInt('' + version, 10);
                if (isNaN(majorVersion)) {
                    version = '' + parseFloat(nVer);
                    majorVersion = parseInt(nVer, 10);
                }
        
                // mobile version
                var mobile = /Mobile|mini|Fennec|Android|iP(ad|od|hone)/.test(nVer);
        
                // cookie
                var cookieEnabled = (navigator.cookieEnabled) ? true : false;
        
                if (typeof navigator.cookieEnabled == 'undefined' && !cookieEnabled) {
                    document.cookie = 'testcookie';
                    cookieEnabled = (document.cookie.indexOf('testcookie') != -1) ? true : false;
                }
        
                // system
                var os = unknown;
                var clientStrings = [
                    {s:'Windows 10', r:/(Windows 10.0|Windows NT 10.0)/},
                    {s:'Windows 8.1', r:/(Windows 8.1|Windows NT 6.3)/},
                    {s:'Windows 8', r:/(Windows 8|Windows NT 6.2)/},
                    {s:'Windows 7', r:/(Windows 7|Windows NT 6.1)/},
                    {s:'Windows Vista', r:/Windows NT 6.0/},
                    {s:'Windows Server 2003', r:/Windows NT 5.2/},
                    {s:'Windows XP', r:/(Windows NT 5.1|Windows XP)/},
                    {s:'Windows 2000', r:/(Windows NT 5.0|Windows 2000)/},
                    {s:'Windows ME', r:/(Win 9x 4.90|Windows ME)/},
                    {s:'Windows 98', r:/(Windows 98|Win98)/},
                    {s:'Windows 95', r:/(Windows 95|Win95|Windows_95)/},
                    {s:'Windows NT 4.0', r:/(Windows NT 4.0|WinNT4.0|WinNT|Windows NT)/},
                    {s:'Windows CE', r:/Windows CE/},
                    {s:'Windows 3.11', r:/Win16/},
                    {s:'Android', r:/Android/},
                    {s:'Open BSD', r:/OpenBSD/},
                    {s:'Sun OS', r:/SunOS/},
                    {s:'Chrome OS', r:/CrOS/},
                    {s:'Linux', r:/(Linux|X11(?!.*CrOS))/},
                    {s:'iOS', r:/(iPhone|iPad|iPod)/},
                    {s:'Mac OS X', r:/Mac OS X/},
                    {s:'Mac OS', r:/(Mac OS|MacPPC|MacIntel|Mac_PowerPC|Macintosh)/},
                    {s:'QNX', r:/QNX/},
                    {s:'UNIX', r:/UNIX/},
                    {s:'BeOS', r:/BeOS/},
                    {s:'OS/2', r:/OS\/2/},
                    {s:'Search Bot', r:/(nuhk|Googlebot|Yammybot|Openbot|Slurp|MSNBot|Ask Jeeves\/Teoma|ia_archiver)/}
                ];
                for (var id in clientStrings) {
                    var cs = clientStrings[id];
                    if (cs.r.test(nAgt)) {
                        os = cs.s;
                        break;
                    }
                }
        
                var osVersion = unknown;
        
                if (/Windows/.test(os)) {
                    osVersion = /Windows (.*)/.exec(os)[1];
                    os = 'Windows';
                }
        
                switch (os) {
                    case 'Mac OS':
                    case 'Mac OS X':
                    case 'Android':
                        osVersion = /(?:Android|Mac OS|Mac OS X|MacPPC|MacIntel|Mac_PowerPC|Macintosh) ([\.\_\d]+)/.exec(nAgt)[1];
                        break;
        
                    case 'iOS':
                        osVersion = /OS (\d+)_(\d+)_?(\d+)?/.exec(nVer);
                        osVersion = osVersion[1] + '.' + osVersion[2] + '.' + (osVersion[3] | 0);
                        break;
                }
            }
        
            self.device_info = {
                screen: screenSize,
                browser: browser,
                browserVersion: version,
                browserMajorVersion: majorVersion,
                mobile: mobile,
                os: os,
                osVersion: osVersion,
            };
        };

        this.prepare_to_save = function(data){
            var x, y, left, right;
            try {
                left = data.eyeFeatures.left;
                right = data.eyeFeatures.right;
                delete left['patch'];
                delete right['patch'];
                x = data.x;
                y = data.y;
                // convert to int32 to reduce size
                x = new Int32Array([x])[0];
                y = new Int32Array([y])[0];
            } catch (error) {
                left = null;
                right = null;
                x = null;
                y = null;
            } finally {
                return {'x':x,'y':y,'eyes':{'left':left, 'right':right}};
            }
        }

        this.nextQuestion = function(ans){

            webgazer.pause();
            var question = self.questions[self.questionIndex];
            if (self.questionIndex == 0) {
                this.save_device_info();
                question.answer['device_info'] = self.device_info;
            }
            question.answer['answerTime'] = Date.now() - self.trialStartTime;
            question.answer['choicePos'] = ans;
            question.answer['choice'] = question.trial.objects[ans];
            question.answer['coordinates'] = self.savePositions();

            let gazeData = {};
            for (let key in self.curGazeData){
                let int_key = new Int32Array([key])[0];
                gazeData[int_key] = self.prepare_to_save(self.curGazeData[key]);
            }
            var encoded = btoa(JSON.stringify(gazeData));
            question.answer['gaze'] = encoded;
            // console.log(question.answer);
            console.log(JSON.parse(atob(encoded)));

            var content = document.getElementById('question_slide_content');

            if (question.answer['choicePos'] == question.trial.trgtPos){
                question.answer['correct'] = 1;
                var feedback = document.getElementById('feedback_correct');
            }
            else{
                question.answer['correct'] = 0;
                var feedback = document.getElementById('feedback_incorrect');
            }
            console.log(question.answer);

            content.style.display = 'none';
            feedback.style.display = 'flex';
            $timeout(function () {
                if(self.questionIndex + 1 < self.questions.length){
                    feedback.style.display = 'none';
                    ++self.questionIndex;
                    self.startTimer();
                    self.curGazeData = {};
                }else{
                    self.next();
                    webgazer.end();
                    return;
                }

            }, 1200);   
            webgazer.resume();
        };


        this.revealStrategyBox = function(ans){
            var question = self.strategyQuestions[self.strategyQuestionIndex];
            question.answer['answerTime'] = Date.now() - self.trialStartTime;
            question.answer['choicePos'] = ans;
            question.answer['choice'] = question.trial.objects[ans];

            // document.getElementById("strategyTable").visibility = 'hidden';
            document.getElementById('img'+ans.slice(-1)).style.border = '2px solid blue'; 
            self.IsEnabled = false;

        };

        this.nextStrategyQuestion = function(){
            if(self.strategyQuestionIndex + 1 < self.strategyQuestions.length){
                ++self.strategyQuestionIndex;
                self.IsEnabled = true;
            }else{
                self.questions = self.questions.concat(self.strategyQuestions);
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

        this.initVideo = function(){
            //start the webgazer just for the video preview
            webgazer.saveDataAcrossSessions(false).begin();
            webgazer.showVideoPreview(true) /* shows video preview */
                .showPredictionPoints(false); 
        };

        this.startCalibration = function(){
            //start the webgazer tracker
            webgazer.end();
            self.experimentStartTime = Date.now();
            webgazer.setRegression('ridge') /* currently must set regression and tracker */
                .setTracker('TFFacemesh')
                .setGazeListener(function(data, clock) {
                    self.curGazeData[clock + self.experimentStartTime - self.trialStartTime] = data;
                })
                .saveDataAcrossSessions(false)
                .begin();
            webgazer.showVideoPreview(true)
                .showPredictionPoints(true) /* shows a square every 100 milliseconds where current prediction is */
                .applyKalmanFilter(true);

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

            self.allStates = ["instructionsSlide","workerIdSlide","specificInstructionsSlide","practiceQuestionSlide","calibrationInstructionsSlide","calibrationSlide","experimentStartSlide","questionSlide","strategySlide","generalQuestionsSlide"];
            // self.allStates = ["workerIdSlide","calibrationInstructionsSlide","calibrationSlide","experimentStartSlide","questionSlide","strategySlide","generalQuestionsSlide"];


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


