var debug = false;

$( document ).ready(function() {
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
            //Ajax events
            success: function (e) {
                dropMessage('Upload completed');
                updateInformations(e);
                $('#actionButtons').find("button#generate").attr("disabled", false);
            },
            error: function (e) {
                alert('error ' + e.message);
            },
            // Form data
                data: formData,
                type: 'POST',
                //Options to tell jQuery not to process data or worry about content-type.
                cache: false,
                contentType: false,
                processData: false
            });
            return false;
    });
    
    $('#reset').bind("click", function(event){
        reset();
    });

    $('#validate').bind("click", function(e){
        validate($(this), "#result");
    });

    $('#download').bind("click", function(e){
        download();
    });

    loadDefinedCatalogs();
    $("#catalogs-selector").bind("click", function(e){
        var clicked = $(e.target);
        clicked.toggleClass("selected");
        // console.debug($(e.target));
    });
    $("#newSchema").keypress(function( event ) {
        if ( event.which == 13 ) {
            event.preventDefault();
            addCatalog($(this).val());
            $(this).val(null);
        }
    });

    loadDefinedXSLs();
    $("#xsl-selector").bind("click", function(e){
        var clicked = $(e.target);
        clicked.toggleClass("selected");
        // console.debug($(e.target));
    });
    // Bind event: if mapping selection changed
    $("#mapping-selector").bind("change", function(event) {
       updateMapping($(this).find("option:selected").val()) ;
    });
    
});

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
            loadDefinedXSLs();
            var data = [];
            data.lines = 0;
            updateInformations(data);
            $("#content").empty();
            $('#generate').attr("disabled", "disabled");
            $("#newSchema").val(null);
            $("#process-from").val(1);
            $('#validate').removeClass("invalid").removeClass("valid");
        })
    .fail(function( jqXHR, textStatus ) {
            alert( "Request failed: " + textStatus );
        });
}

function updateMapping(mapping) {
    toggleAfterProcessButtons(false);
    loadDefinedCatalogs();
    loadDefinedXSLs();
    $("#content").empty();
    $("#newSchema").val(null);
    $("#process-from").val(1);
    $('#validate').removeClass("invalid").removeClass("valid");
    // alert(mapping);
}

function loadDefinedCatalogs() {
    var catalogSelector = $("#catalogs-selector");
    var mapping = $("select#mapping-selector option:selected").val();
    // console.debug(catalogSelector);
    $.ajax({
        url: "process-csv.xq",
        method: "POST",
        data: { 
            action: "getCatalogs",
            mapping: mapping
        }
    })
    .success(function( msg ) {
        catalogSelector.empty();
        $.each(msg.catalogs, function(index, catalog){
            addCatalog(catalog.uri, catalog.active);
        });
    });
}

function loadDefinedXSLs() {
    var xslSelector = $("#xsl-selector");
    var mapping = $("select#mapping-selector option:selected").val();
    // console.debug(catalogSelector);
    $.ajax({
        url: "process-csv.xq",
        method: "POST",
        data: { 
            action: "getXSLs",
            mapping: mapping
        }
    })
    .success(function( msg ) {
        xslSelector.empty();
        if(msg !== null){
            $.each(msg.xsl, function(index, xsl){
                // console.debug(x);
                if(xsl.active=="true")  addXSL(xsl.uri, xsl.selected);
            });
        }
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
    xslSelector.append(newDiv);
}

function toggleAfterProcessButtons(toggle) {
    var actionButtonsContainer = $('#actionButtons');
    actionButtonsContainer.find('#validate').attr("disabled", !toggle);
    actionButtonsContainer.find('#download').attr("disabled", !toggle);
}

function updateInformations(data) {
    $('.lines-amount').html(data.lines);
    $('#process-to').attr("value", data.lines);
}

function dropMessage(message, clear){
    var messagesDiv = $('#messages');
    if (clear){
        messagesDiv.empty();
    }
    var messageNode = $("<div class=\"success\">" + message + "</div>").delay(3000).fadeOut(function(){messagesDiv.empty();});
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


function generate(button, result, mapping, start, end) {
    buttonSetProgressing(button, true);
    var selectedXsls = $("#xsl-selector .selected");
    var xsls = [];
    $.each(selectedXsls, function(idx, val) {
        xsls.push($(val).html());
    });
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
    request.success(function( xml ) {
        button.removeClass("progressing");
        button.attr("disabled", false);
        result.html("<xmp class=\"prettyprint linenums\">" +
                new XMLSerializer().serializeToString(xml) +
            "</xmp>");

        prettyPrint();
        toggleAfterProcessButtons(true);
    });
 
    request.error(function( jqXHR, textStatus ) {
        alert( "Request failed: " + textStatus );
    });
}

function validate(button) {
    var catalogs = [];
    $.each($("#catalogs-selector > div.selected"), function(index, value){
        catalogs.push($(value).html());
    });
    
    buttonSetProgressing(button, true);
    var request = $.ajax({
        url: "process-csv.xq",
        method: "POST",
        data: { 
            action: "validate",
            catalogs: catalogs
        }
    })
        .success(function( msg ) {
            window.open('validation-result.xq', '_blank');
            if(msg.result == "invalid")
                $(button).addClass("invalid").removeClass("valid");
            else
                $(button).addClass("valid").removeClass("invalid");
            console.debug(result);
    })
        .error(function( result ) {
            alert( "Request failed: " + result.responseText );
    })
        .done(function(msg){
            button.removeClass("progressing");
            button.attr("disabled", false);
    });
}

function download() {
    window.open("download.xq");
}