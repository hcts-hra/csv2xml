var debug = false;
var advanced = true;
var messageFadeOutTime = 3000;

$( document ).ready(function() {
    // reset();
    toggleAfterProcessButtons(false);

    $('form#csv-upload').bind('submit', function(event) {
        event.stopPropagation();
        event.preventDefault();
        files = event.target.files;
        // Update button text.
        var button = $(this).find('button[type="submit"]');
        // buttonSetProgressing(button, true);
        var file = $('#inputFiles').get(0).files[0];
        var formData = new FormData();
        formData.append('file', file);
        
        // console.debug(formData);
        $.ajax({
            url: 'upload.xq',
            // Form data
            data: formData,
            type: 'POST',
            //Options to tell jQuery not to process data or worry about content-type.
            cache: false,
            contentType: false,
            processData: false,
            //Ajax events
            success: function (msg) {
                uploadingDone(true, msg);
            },
            error: function (msg) {
                uploadingDone(false, msg);
                alert('error ' + msg.message);
            },
            done: function (msg) {
            }
        });
        return false;
    });
    
    $('#reset').bind("click", function(event){
        reset();
    });

    $('#validate').bind("click", function(e){
        validate($(this));
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

    // Bind event: if mapping selection changed
    $("#mapping-selector").bind("change", function(event) {
       updateMapping();
    });
    
    //Bind event: if transformations selection changed
    $("#transformations-selector").bind("change", function(event) {
        // console.debug("TRANS CHANGED"); 
        loadDefinedXSLs();
    });
    
    $("#xsl-selector").bind("change", function (event) {
        // body...
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
        
        console.debug($('#validate'));
    });
    
    //Bind advanced mode checkbox
    $("#advancedMode").bind("change", function(event){
        enableAdvancedMode(this.checked);
    });

    // Bind "doAll" button
    $("#doAll").bind("click", function(event){
        doEverything($(this));
    });

    updateMapping() ;

    enableAdvancedMode(advanced);
    
});


// Enable/Disable functionality after 
function uploadingDone(success, msg){
    if (success){
        dropMessage('Upload successful.');
        updateInformations(msg);
    }
    else{
        dropMessage('Upload failed.');
    }
    
    $('#generate').attr("disabled", !success);
    $('#doAll').attr("disabled", !success);
}

function enableAdvancedMode(enable) {
    $('#advancedMode').attr("checked", enable);
    console.debug(enable);
    var t_options = {duration: "slow", easing: "slide"};
    if (enable){
        //Show advanced menu options
        $('.advanced').show(t_options);
        //Hide simple menu options
        $('.simple').hide(t_options);
    } else {
        //Hide advanced menu options
        $('.advanced').hide(t_options);
        //show simple menu options
        $('.simple').show(t_options);
    }
}

function reset() {
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
            $('form#csv-upload').trigger("reset");
            dropMessage("Session resetted.", true);
            toggleAfterProcessButtons(false);
            loadDefinedCatalogs();
            loadDefinedTransformations();
            var data = [];
            data.lines = 0;
            updateInformations(data);
            $("#result-container").empty();
            $('#generate').attr("disabled", "disabled");
            $("#newSchema").val(null);
            $("#process-from").val(1);
            $('#validate').removeClass("invalid").removeClass("valid");
            $('#doAll').removeClass("invalid").removeClass("valid");
        })
    .fail(function( jqXHR, textStatus ) {
        alert( "Request failed: " + textStatus );
    });
}

function updateMapping() {
    // console.debug("updating mapping");
    toggleAfterProcessButtons(false);
    loadDefinedTransformations(function(msg){});
    
    $("#result-container").empty();
    $("#newSchema").val(null);
    $("#process-from").val(1);
    $('#validate').removeClass("invalid").removeClass("valid");
}

function loadDefinedCatalogs(callback) {
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
    .success(function( msg ) {
        catalogSelector.empty();
        if (msg)
            $.each(msg.catalogs, function(index, catalog){
                addCatalog(catalog.uri, catalog.active);
            });
    })
    .done(function (msg) {
        $("#catalogs-selector").trigger("change");
        if(callback) callback(msg);
    });
}

function loadDefinedTransformations(callback) {
    console.debug("updatingTransformations");
    var transSelector = $("#transformations-selector");
    var mapping = $("select#mapping-selector option:selected").val();
    // console.debug(catalogSelector);
    $.ajax({
        url: "process-csv.xq",
        method: "POST",
        data: { 
            action: "getTransformations",
            mapping: mapping
        }
    })
    .success(function( msg ) {
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
    })
    .done(function( msg ){
        $("#transformations-selector").trigger("change");
        if(callback) callback(msg);
    });
}


function loadDefinedXSLs(callback) {
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
    .success(function( msg ) {
        xslSelector.empty();
        if(msg !== null){
            $.each(msg.xsl, function(index, xsl){
                // console.debug(x);
                if(xsl.active=="true") addXSL(xsl.uri, xsl.selected);
            });
        }
    })
    .done(function ( msg ) {
        $("#xsl-selector").trigger("change");
        if (callback) callback(msg);
    });
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
    actionButtonsContainer.find('button').removeClass("processing");
    actionButtonsContainer.find('#download').attr("disabled", !toggle);
    actionButtonsContainer.find('#doAll').attr("disabled", !toggle);
}

function updateInformations(data) {
    console.debug(data);
    $('.lines-amount').html(data.lines);
    $('#process-to').attr("value", data.lines);
}

function dropMessage(message, clear, noFadeOut){
    console.debug(message);
    var messagesDiv = $('#messages');
    if (clear){
        messagesDiv.empty();
    }
    var messageNode = $("<div class=\"success\">" + message + "</div>");
    if (!noFadeOut) messageNode.delay(messageFadeOutTime).fadeOut(function(){messagesDiv.empty();});
    messagesDiv.append(messageNode);
}

function buttonSetProgressing(button, progressing){
    if (progressing){
        button.attr('disabled', 'disabled');
        button.addClass("progressing");
    }else{
        button.attr('disabled', '');
        button.removeClass("progressing");
    }
}


function generate(button, callback) {
    var resultContainer = $('#result-container');
    var mapping = $('#mapping-selector option:selected').val();
    var start = $('#process-from').val();
    var end = $('#process-to').val();
    buttonSetProgressing(button, true);
    var selectedXsls = $("#xsl-selector .selected");
    var xsls = [];
    $.each(selectedXsls, function(idx, val) {
        xsls.push($(val).html());
    });
    var result;
    // console.debug("start: " + start);
    // console.debug("end: " + end);
    // console.debug("debug: " + debug);
    var request = $.ajax({
        url: "process-csv.xq",
        method: "POST",
        data: { 
            action: "generate",
            contentType: "text/plain",
            dataType: "xml",
            debug: debug,
            mapping: mapping,
            start: start,
            end: end,
            xsls: xsls
        }
    });
    request.done(function( xml ) {
        button.removeClass("progressing");
        button.attr("disabled", false);
        resultContainer.html("<xmp class=\"prettyprint linenums\">" +
                new XMLSerializer().serializeToString(xml) +
            "</xmp>");

        prettyPrint();
        toggleAfterProcessButtons(true);
        if(callback) callback(true, xml);
    });
    request.fail(function( jqXHR, textStatus ) {
        alert( "Request failed: " + textStatus );
        if(callback) callback(false, msg);
    });
}

function validate(button, callback) {
    var catalogs = [];
    $.each($("#catalogs-selector > div.selected"), function(index, value){
        catalogs.push($(value).html());
    });
    if (catalogs.length > 0) {
        buttonSetProgressing(button, true);
        var result = false;
        var request = 
            $.ajax({
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
                alert( "Request failed: " + result.responseText );
            })
            .done(function(msg){
                if(msg.result == "invalid") {
                    for (var i=1; i <= msg.reports; i++){
                        window.open('validation-result.xq?reportNr=' + i , '_blank');
                }
                        $(button).addClass("invalid").removeClass("valid");
                }else {
                    $(button).addClass("valid").removeClass("invalid");
                }
                button.removeClass("progressing");
                button.attr("disabled", false);
                if(callback) callback((msg.result == "invalid")?false:true, msg);
            });
    } else {
        dropMessage("no schema to validation against", false, true);
    }
}

function doEverything(button) {
    // buttonSetProgressing(button, true);
    dropMessage("generating...", true, true);
    generate(button, function(result, message){
        // if successfully generated, then validate
        if(result){
            dropMessage("generating successful. Please be patient, validating now...", false, true);
            validate(button, function(result, msg){
                var downloadButton = '<a href="download.xq" target="_blank">Download</a>';
                if (result) {
                    dropMessage('<span class="message ok">Validation passed successfully.</span> <b>' + downloadButton + "</b>", false, true);
                    window.open("download.xq");
                } else {
                    dropMessage("<span class='message warning'>WARNING: Validation failed. Download anyway?</span> <b>" + downloadButton + "</b>", false, true);
                }
            });
        } else {
            dropMessage("generating failed: " + message, false, true);
        }
    });
}

function download() {
    window.open("download.xq");
}