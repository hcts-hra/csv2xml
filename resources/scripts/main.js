var debug = false;
var advanced = false;
var messageFadeOutTime = 3000;
var preview = true;
var displayLog = true;
var interruptProcessing = false;

$( document ).ready(function() {
    // reset();
    initLogDialog(displayLog);
    toggleAfterProcessButtons(false);
    $('#applyXSL').attr("disabled", "disabled");

    $('form#csv-upload').bind('submit', function(event) {
        event.stopPropagation();
        event.preventDefault();
        files = event.target.files;
        var button = $(this).find('button[type="submit"]');
        var file = $('#inputFiles').get(0).files[0];
        var formData = new FormData();
        formData.append('file', file);
        //Disable form buttons
        buttonSetProgressing(button, true);
        $('#generatePreview').attr("disabled", "disabled");
        $('#inputFiles').attr("disabled", "true");
        $('#generate').attr("disabled", "disabled");
        resetSession(function(msg){
            // console.debug(formData);
            $.ajax({
                url: 'upload.xq',
                // Form data
                data: formData,
                type: 'POST',
                //Options to tell jQuery not to process data or worry about content-type.
                cache: false,
                contentType: false,
                processData: false
            })
                //Ajax events
            .done(function (msg) {
                uploadingDone(true, msg);
                dropMessage('CSV upload successful', "success");
            })
            .fail(function (msg) {
                uploadingDone(false, msg);
                alert('error ' + msg.message);
            })
            .complete(function (msg) {
                buttonSetProgressing(button, false);
                $('#inputFiles').removeAttr("disabled");
                $('#applyXSL').attr("disabled", "disabled");
            });
            return false;
        });
    });

    $('#toggle-log').bind("click", function(event){
       ($("#log-dialog").dialog("isOpen") === false) ? $("#log-dialog").dialog("open") : $("#log-dialog").dialog("close");
    });
    
    $('#reset').bind("click", function(event){
        reset();
    });

    $('#validate').bind("click", function(e){
        validate();
    });

    $('#download').bind("click", function(e){
        download();
    });

    $("#newSchema").keypress(function( event ) {
        if ( event.which == 13 ) {
            event.preventDefault();
            addCatalog($(this).val());
            $(this).val(null);
        }
    });

    $.when(init()).done(function (argument) {
        // Bind event: if mapping selection changed
        $("#mapping-selector").bind("change", function() {
            updateMapping();
        });
        
        //Bind event: if transformations selection changed
        $("#transformations-selector").bind("change", function(event) {
            // console.debug("TRANS CHANGED"); 
            loadDefinedXSLs();
        });
    
        $("#xsl-selector").bind("change", function (event) {
            loadDefinedCatalogs();
        });
    
        $("#xsl-selector").bind("click", function(e){
            var clicked = $(e.target);
            clicked.toggleClass("selected");
            // console.debug($(e.target));
        });
    
        $("#catalogs-selector").bind("click", function(e){
            var clicked = $(e.target);
            clicked.toggleClass("selected");
            //if no validation catalog selected, disable validation function
            if(parseInt($('#lines-count > .lines-amount').html(), 10) === 0 || $(this).children(".selected").length === 0)
                $('#validate').attr("disabled", "disabled");
            else
                $('#validate').attr("disabled", false);
            
            // console.debug($('#validate'));
        });
    });

    //Bind advanced mode checkbox
    $("#advancedMode").bind("change", function(event){
        enableAdvancedMode(this.checked);
    });

    // Bind "doAll" button
    $("#doAll").bind("click", function(event){
        doEverything($(this));
    });
    
    //Bind "applyXSL" button
    $("#applyXSL").bind("click", function(event) {
        applyXSL();
    });

    //Bind "display Preview" button
    $('#generatePreview').attr("disabled", "disabled");
    $('#generatePreview').bind("click", function(event) {
        initPreview();
    });


    enableAdvancedMode(advanced);

});

function init() {
    var dfd = $.Deferred();
    $.when(updateMapping()).done(dfd.resolve());
    return dfd.promise();
}

function initLogDialog(displayOnInit) {
    $("#log-dialog").dialog({
        title:  "Log",
        height: 400,
        position: { my: "right center", at: "right center", of: window }
    });

}


// Enable/Disable functionality after 
function uploadingDone(success, msg){
    if (success){
        dropMessage('Upload successful.', "success");
        updateInformations(msg);
    }
    else{
        dropMessage('Upload failed.', "error");
    }
    
    $('#generate').attr("disabled", !success);
    $('#doAll').attr("disabled", !success);
}

function enableAdvancedMode(enable) {
    // console.debug(enable);
    var t_options = {duration: "slow", easing: "slide"};
    if (enable){
        //Show advanced menu options
        $('.advanced').show(t_options);
        //Hide simple menu options
        $('.simple').hide(t_options);
        $('#advancedMode').attr("checked", "checked");
    } else {
        //Hide advanced menu options
        $('.advanced').hide(t_options);
        //show simple menu options
        $('.simple').show(t_options);
        $('#advancedMode').removeAttr("checked");
    }
}

function resetSession(callback) {
    $.ajax({
            url: "process-csv.xq",
            method: "POST",
            data: { 
                action: "reset",
                contentType: false,
                processData: false
            }
        })
        .done(function( msg ) {
            dropMessage("Session resetted.", "success");
            updateMapping();
            if(callback) callback(msg);
        })
        .fail(function( jqXHR, textStatus ) {
            alert( "Request failed: " + textStatus );
        });
}

function reset() {
    resetSession(function(msg){
        loadDefinedCatalogs();
        loadDefinedTransformations();
        var data = [];
        data.lines = 0;
        updateInformations(data);
        $("#result-container").empty();
        $("#newSchema").val(null);
        $("#process-from").val(1);
        $('#validate').removeClass("invalid").removeClass("valid");
        $('#doAll').removeClass("invalid").removeClass("valid");
        $('#inputFiles').removeAttr("disabled");
        $('#csv-upload').find('button[type="submit"]').removeAttr("disabled");
        $('#generate').attr("disabled", "disabled");
        $('#applyXSL').attr("disabled", "disabled");
        $('#generatePreview').attr("disabled", "disabled");
        toggleAfterProcessButtons(false);
        $('#transformSelector').empty();
        $('#result-pagination').empty();
        }
    );
}

function updateMapping() {
    var dfd = $.Deferred();
    console.debug("updating mapping");

    toggleAfterProcessButtons(false);
    $('#validate').removeClass("invalid").removeClass("valid");
    
    $("#result-container").empty();
    $("#newSchema").val(null);

    var mapping = $("select#mapping-selector option:selected").val();

    $.ajax({
        url: "process-csv.xq",
        method: "POST",
        data: { 
            action: "updateMapping",
            mapping: mapping,
        }
    })
    .done(function( msg ) {
        var startingLine = (msg === true)?2:1;
        $("#process-from").val(startingLine);
        console.debug("updating mapping completed");
        loadDefinedTransformations().done(dfd.resolve(msg));
    })
    .fail(function(msg) {
        console.debug(msg);
    });

    return dfd.promise();
}


function loadDefinedTransformations(callback) {
    var dfd = $.Deferred();

    console.debug("updatingTransformations");
    var transSelector = $("#transformations-selector");
    var mapping = $("select#mapping-selector option:selected").val();
    $.ajax({
        url: "process-csv.xq",
        method: "POST",
        data: { 
            action: "getTransformations",
            mapping: mapping
        }
    })
    .done(function( msg ) {
        transSelector.empty();
        if(msg !== null){
            $.each(msg.transform, function(index, trans){
                if (trans.active == "true"){
                    if (trans.selected) 
                        msg.selectedTrans = trans.name;
                    var selected = (trans.selected == 'true' ? ' selected="selected"' : '');
                    var option = "<option" + selected + " value=\"" + trans.name + "\">" + trans.label + "</option>";
                    transSelector.append(option);
                }
            });
        }
        console.debug("load transformations completed");
        if(callback) callback(msg);
        loadDefinedXSLs().done(dfd.resolve());
    });
    return dfd.promise();
}


function loadDefinedXSLs(callback) {
    // set validation and download "disabled"
    $("#validate").attr("disabled", "disabled");
    $("#download").attr("disabled", "disabled");
    
    var dfd = $.Deferred();
    
    console.debug("updatingXSLXs");
    var xslSelector = $("#xsl-selector");
    var mapping = $("select#mapping-selector option:selected").val();
    var transformation = $("select#transformations-selector option:selected").val();
    // console.debug(catalogSelector);
    $.ajax({
        url: "process-csv.xq",
        method: "POST",
        data: { 
            action: "getXSLs",
            mapping: mapping,
            transformation: transformation
        }
    })
    .done(function ( msg ) {
        xslSelector.empty();
        if(msg !== null){
            $.each(msg.xsl, function(index, xsl){
                // console.debug(x);
                if(xsl.active=="true") addXSL(xsl.uri, xsl.selected);
            });
        }
        // $("#xsl-selector").trigger("change");
        console.debug("load XSLs completed");
        if (callback) callback(msg);
        loadDefinedCatalogs().done(dfd.resolve());
    });
    return dfd.promise();
}

function loadDefinedCatalogs(callback) {
    var dfd = $.Deferred();
    
    console.debug("updating catalogs");
    var catalogSelector = $("#catalogs-selector");
    var mapping = $("select#mapping-selector option:selected").val();
    var trans = $("select#transformations-selector option:selected").val();
    // console.debug(catalogSelector);
    $.ajax({
        url: "process-csv.xq",
        method: "POST",
        data: { 
            action: "getCatalogs",
            mapping: mapping,
            trans: trans
        }
    })
    .done(function (msg) {
        catalogSelector.empty();
        if (msg)
            $.each(msg.catalogs, function(index, catalog){
                addCatalog(catalog.uri, catalog.active);
            });
        // $("#catalogs-selector").trigger("change");
        if(callback) callback(msg);
        console.debug("updating catalogs completed");
        dfd.resolve();
    });
    return dfd.promise();
}


function addCatalog(uri, active){
    var catalogSelector = $("#catalogs-selector");
    var newDiv = $("<div>");
    if (active == "true") newDiv.addClass("selected");
    newDiv.html(uri);
    catalogSelector.append(newDiv);
}

function addXSL(uri, selected){
    var xslSelector = $("#xsl-selector");
    var newDiv = $("<div>");
    if (selected == "true") newDiv.addClass("selected");
    newDiv.html(uri);
    xslSelector.bind("click", function (event) {
        $("#xsl-selector").trigger("change");
    });
    xslSelector.append(newDiv);
}

function toggleAfterProcessButtons(toggle) {
    var actionButtonsContainer = $('#actionButtons');
    if(!toggle && (parseInt($('#lines-count > .lines-amount').html(), 10) === 0 || $(this).children(".selected").length === 0)){
        actionButtonsContainer.find('#validate').attr("disabled", !toggle);
    } else {
        actionButtonsContainer.find('#validate').attr("disabled", false);
    }
    actionButtonsContainer.find('button').removeClass("progressing");
    actionButtonsContainer.find('#download').attr("disabled", !toggle);
    if(advanced) actionButtonsContainer.find('#doAll').attr("disabled", !toggle);
}

function updateInformations(data) {
    // console.debug(data);
    $('.lines-amount').html(data.lines);
    $('#process-to').attr("value", data.lines);
}

function dropMessage(message, msgclass){
    var now = new Date(jQuery.now());
    var logTime = now.toLocaleTimeString();
    var messagesDiv = $('#log-dialog');
    var messageNode = $("<div><span>" + logTime + "</span>: <span class=\"" + msgclass + "\">" + message + "</span></div>");
    
    messagesDiv.prepend(messageNode);    
}

function buttonSetProgressing(button, progressing){
    if (progressing){
        button.attr('disabled', 'disabled');
        button.addClass("progressing");
    }else{
        button.removeAttr('disabled');
        button.removeClass("progressing");
    }
}

function loadTemplates(mapping) {
    var df = $.Deferred();
    dropMessage("<b>loadingTemplates</b>", "info");
    var request = $.ajax({
        url: "process-csv.xq",
        method: "POST",
        data: { 
            action: "loadTemplates",
            debug: debug,
            mapping: mapping,
        }
    })
    .success(function( msg ) {
        $.each(msg.template, function(i, template){
            dropMessage("template loaded: " + template.key, "success");
        });
        df.resolve(msg.status);
    });
    return df.promise();
}

function generate(button, callback) {
    var df = $.Deferred();
    var mapping = $("select#mapping-selector option:selected").val();
    var start = $('#process-from').val();
    var end = $('#process-to').val();
    // load templates
    $.when(loadTemplates(mapping))
        .then(function(){
            var result;
            var resultContainer = $('#result-container');
            resultContainer.html("<xmp class=\"prettyprint linenums\"></xmp>");
            // generate Parent
            dropMessage("<b>Generating parent document...</b>", "info");
            var generateParent = $.ajax({
                url: "process-csv.xq",
                method: "POST",
                data: { 
                    action: "storeParent",
                    processData: false,
                    dataType: "json",
                    debug: debug,
                    mapping: mapping,
                    start: start,
                }
            })
            // process Lines
            .done(function(msg){
                dropMessage("->" + msg, "success");
                dropMessage("<b>Start processing " + (end - start + 1) + " lines</b>", "info");
                var processingStack = [];
                for (var actualLine = start; actualLine <= end; actualLine++) processingStack.push(actualLine);
                $.when(generateLinesXML(processingStack)).then(function (argument) {
                    dropMessage("test");
                });
            })
            .fail(function(msg){
                dropMessage("...error: " + msg.responseText, "error");
            })
            .complete(function(msg){
            });
        });
    return df.promise();
}

function applyXSL() {
    var df = $.Deferred();
    // dropMessage("applyingXSLs", "info");
    var selectedXsls = $("#xsl-selector .selected");
    var xsls = [];
    $.each(selectedXsls, function(idx, val) {
        xsls.push($(val).html());
    });

    // if (xsls.length > 0){
    var button = $("#applyXSL");
    var transName = $("select#transformations-selector option:selected").val();
    // first save selected transformation settings
    var saveTrans = $.ajax({
                url: "process-csv.xq",
                method: "POST",
                data: {
                    action: "saveSelectedTransPreset",
                    selectedPresetName: transName
                }
            })
    .done(function(msg) {
        dropMessage("<b>applying transformations</b>", "info");
        $.ajax({
            url: "process-csv.xq",
            method: "POST",
            data: { 
                action: "generateTransformation",
                processData: false,
                dataType: "json",
                debug: debug,
                xsls: xsls 
            }
        })
        .done(function(msg) {
            dropMessage("Transformation successful: " +  msg.xmlFilename, "success");
            $('#generatePreview').removeAttr('disabled');
            toggleAfterProcessButtons(true);            
            $.when(postProcessing()).done(
                initPreview(),
                df.resolve()

            );
        })
        .fail(function(msg) {
            dropMessage("XSL Transformations failed. " + msg.responseText, "error");
            df.reject();
        });
    });
    saveTrans.fail(function(msg) {
            dropMessage("save Trans failed. " + msg.responseText, "error");
            df.reject();
    });

    return df.promise();
}

function generateLinesXML(lineStack) {
    var df = $.Deferred();

    var generateButton = $('#generate');
    buttonSetProgressing(generateButton, true);
    buttonSetProgressing($('#doAll'), true);

    var mapping = $("select#mapping-selector option:selected").val();
    // Take the first value from stash process it
    var line = lineStack.shift();
    $.ajax({
        url: "process-csv.xq",
        method: "POST",
        data: { 
            action: "processCSVLine",
            contentType: "text/plain",
            dataType: "xml",
            debug: debug,
            mapping: mapping,
            line: line
        }
    })
    .done(function( xml ) {
        dropMessage("line " + line + " processed.", "success");
    })
    .fail(function(msg ) {
        dropMessage("XML generation failed (Line No " + line + "): " + msg.responseText, "error");
    })
    .complete(function(msg){
        // recursive call with rest of stack
        if (lineStack.length > 0){
            generateLinesXML(lineStack);
        }else{
            dropMessage("Processing CSV Lines done</b>", "success");
            $.when(applyXSL()).done( function (){
                $('#applyXSL').removeAttr("disabled");
                buttonSetProgressing(generateButton, false);
                buttonSetProgressing($('#doAll'), false);
                df.resolve();
            });
        }
    });
    
    return df.promise();
}

function postProcessing() {
    var df = $.Deferred();
    $.ajax({
        url: "process-csv.xq",
        method: "POST",
        data: { 
            action: "cleanupXML"
        }
    })
    .done(function(result){
        // simple mode, so do all the post-processing
        if(!$("#advancedMode").attr("checked")){
            // dropMessage("generating successful. Please be patient, validating now...", "success");
            validate();
        }
        df.resolve();
    });
    return df.promise();
}

function validate(callback) {
    var button = $('#validate');
    var df = $.Deferred();
    var catalogs = [];
    $.each($("#catalogs-selector > div.selected"), function(index, value){
        catalogs.push($(value).html());
    });
    if (catalogs.length > 0) {
        dropMessage("<b>validating... please be patient.</b>", "info");
        buttonSetProgressing(button, true);
        buttonSetProgressing($('#doAll'), true);
        return $.ajax({
                    url: "process-csv.xq",
                    method: "POST",
                    data: { 
                        action: "validate",
                        catalogs: catalogs
                    }
                })
                .fail(function(result){
                    button.removeClass("progressing");
                    button.attr("disabled", false);
                    dropMessage("Error: " + result.responseText, "error");
                })
                .done(function(msg){
                    var resultDisplay = "";
                    if(msg.result == "invalid") {
                        for (var i=1; i <= msg.reports; i++){
                            window.open('validation-result.xq?reportNr=' + i , '_blank');
                        }
                        $(button).addClass("invalid").removeClass("valid");
                        $("#doAll").addClass("invalid").removeClass("valid");
                        resultDisplay = '<span class="error">invalid</span>';
                    }else {
                        $(button).addClass("valid").removeClass("invalid");
                        $("#doAll").addClass("valid").removeClass("invalid");
                        resultDisplay = '<span class="success">valid</span>';
                    }
                    if(callback) callback((msg.result == "invalid")?false:true, msg);
                    dropMessage("validation completed: resulting xml is <b>" + resultDisplay + "</b>", "info");
                })
                .complete(function(argument) {
                    buttonSetProgressing(button, false);
                    buttonSetProgressing($('#doAll'), false);
                });
    } else {
        dropMessage("no schema to validation against", "error");
        return df.reject();
    }
}

function doEverything(button) {
    // buttonSetProgressing(button, true);
    dropMessage("generating...", "info");
    // generate(button, function(result, message){
    $.when(generate(button)).then(function(result, message){
        // if successfully generated, then validate
        if(result){
            dropMessage("generating successful. Please be patient, validating now...", "success");
            validate(function(result, msg){
                var downloadButton = '<a href="download.xq" target="_blank">Download</a>';
                if (result) {
                    dropMessage('<span class="message ok">Validation passed successfully.</span> <b>' + downloadButton + "</b>", "success");
                    window.open("download.xq");
                } else {
                    dropMessage("<span class='message warning'>WARNING: Validation failed. Download anyway?</span> <b>" + downloadButton + "</b>", "error");
                }
            });
        } else {
            dropMessage("generating failed: " + message, "error");
        }
    });
}

function initPreview() {
    dropMessage("displaying Preview", "info");
    $.ajax({
        url: "process-csv.xq",
        method: "POST",
        data: { 
            action: "countPaginationItems",
            contentType: "text/plain",
            dataType: "json"
            }
        })
        .done(function(pages){
            updateResultPagination(1, pages, 1);
        });

}

function displayPreview(itemNo) {
    $.ajax({
        url: "process-csv.xq",
        method: "POST",
        data: { 
            action: "getPaginationItem",
            contentType: "text/plain",
            dataType: "xml",
            itemNo: itemNo
        }
    })
    .done(function( xml ) {
        var resultContainer = $('#result-container');
        resultContainer.html("<xmp class=\"prettyprint linenums\">" +
        new XMLSerializer().serializeToString(xml) +
            "</xmp>");
        prettyPrint();
    })
    .fail(function( jqXHR, textStatus ) {
    });
    
}

// function getPaginationItem(itemNo) {
//     $.ajax({
//         url: "process-csv.xq",
//         method: "POST",
//         data: { 
//             action: "getPaginationItem",
//             contentType: "text/plain",
//             dataType: "xml",
//             itemNo: itemNo
//         }
//     })
//     .done(function( xml ) {
//         var resultContainer = $('#result-container');
//         resultContainer.html("<xmp class=\"prettyprint linenums\">" +
//         new XMLSerializer().serializeToString(xml) +
//             "</xmp>");
//         prettyPrint();
//     });
// }

function updateResultPagination(start, end, active) {
    var paginationDivs = $('.result-pagination');
    var navPrevious = $('<button type="button" onclick="updateResultPagination(' + start + ', ' + end + ', ' + (active - 1) + ')";>&lt;-</button>');
    // var pageDisplay = $('<span><input type="text" style="width:5em;" value="' + active + '" />' + '/' + end + '</span>');
    var pageDisplay = $('<span>' + active + ' / ' + end + '</span>');
    var navNext = $('<button type="button" onclick="updateResultPagination(' + start + ', ' + end + ', ' + (active + 1) + ')";>-&gt;</button>');
    paginationDivs.empty();
    if (active > start) paginationDivs.append(navPrevious);
    paginationDivs.append(pageDisplay);
    if (active < end) paginationDivs.append(navNext);
    displayPreview(active);
}

function download() {
    window.open("download.xq");
}