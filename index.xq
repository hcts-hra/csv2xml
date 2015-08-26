xquery version "3.0";

import module namespace xml-functions="http://hra.uni-heidelberg.de/ns/csv2vra/xml-functions" at "modules/xml-functions.xqm";
import module namespace config="http://hra.uni-heidelberg.de/ns/csv2vra/config" at "modules/config.xqm";

declare namespace output="http://www.w3.org/2010/xslt-xquery-serialization";

declare option output:method "html5";
declare option output:media-type "text/html";

declare variable $local:app-version := $config:expath-descriptor/@version/string();

let $cors-header := response:set-header("Access-Control-Allow-Origin", "*")
let $data := session:get-attribute("data")
let $debug := request:get-parameter("debug", ())
let $set-session := session:set-attribute("debug", ())

return
    <html>
        <head>
            <title>CSV2XML</title>
            <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
            <meta data-template="config:app-meta"/>
            <link rel="shortcut icon" href="$shared/resources/images/exist_icon_16x16.ico"/>
            <link rel="stylesheet" type="text/css" href="resources/css/style.css"/>
            <script type="text/javascript" src="$shared/resources/scripts/jquery/jquery-1.7.1.min.js"/>
            <script type="text/javascript" src="$shared/resources/scripts/jquery/jquery-ui.min.js"/>
            <script type="text/javascript" src="$shared/resources/scripts/bootstrap-3.0.3.min.js"/>
            <link rel="stylesheet" type="text/css" href="$shared/resources/scripts/jquery/css/smoothness/jquery.ui.all.css" />
            <link rel="stylesheet" type="text/css" href="resources/tools/google-prettify/prettify.css"></link>
            <script src="resources/tools/google-prettify/prettify.js"></script>
    
            <script type="text/javascript" src="resources/scripts/main.js"/>
        </head>
        <body>
            <div id="log-dialog" class="log"></div>
            <div id="git-version">App-Version: <span>{$local:app-version}</span></div>
            <div>
                <button id="reset" type="button">Reset</button>
                <button id="toggle-log" type="button">toggle log</button>
            </div>
            {
                if(not(empty($debug))) then
                    <div>
                        <button class="openDebugWindow" onclick="window.open('debug-output.xq');">open Debug</button>
                    </div>
                else
                    ()
            }
            <div id="messages"></div>
            <div id="menu">
                <div style="float:right">
                    <input type="checkbox" id="advancedMode" />advanced Mode
                </div>
                <div>
                    <div id="upload-mask">
                        <form id="csv-upload" enctype="multipart/form-data" method="post" action="upload.xq">
                            <div>Upload CSV</div>
                            <div class="form-group">
                                <input type="file" id="inputFiles" name="file"/>
                                <button type="submit" class="btn btn-default">Upload</button>
                            </div>
                        </form>
                    </div>
                    <div id="upload-result">
                        <div id="upload-message"></div>
                        <div id="lines-count">
                            <span class="lines-amount">{count($data/line)}</span> lines loaded
                        </div>
                    </div>
                    <div>
                        <span>
                            process lines <input type="text" id="process-from" value="1" size="3em"/> to <input class="lines-amount" type="text" id="process-to" value="{count($data/line)}" size="3em"/>
                        </span>
                    </div>
                    <div>
                        <span>mapping:</span>
                        <select id="mapping-selector">
                        {
                            for $mapping in $xml-functions:mapping-definitions//mapping[@active="true"]
                                let $is-selected := $mapping/@selected/string()
                                return 
                                    if ($is-selected = "true") then
                                        <option value="{$mapping/collection/string()}" selected="selected">{$mapping/name/string()}</option>
                                    else
                                        <option value="{$mapping/collection/string()}">{$mapping/name/string()}</option>
                        }
                        </select>
                    </div>
                    <div>
                        <button id="generate" class="advanced" type="button" onclick="generate($(this));" disabled="disabled">generate XML</button>
                    </div>
                    <div>
                        <span>transform preset:</span>
                        <select id="transformations-selector">
                        </select>
                    </div>
                    <div class="advanced">
                        Apply XSLs (for transformation):
                        <div id="xsl-selector"></div>
                    </div>
                    <div style="font-size:8px">(modifying the predefined selection may break pagination)</div>
                    <div>
                        <button id="applyXSL" class="advanced" type="button" disabled="disabled">transform XML</button>
                    </div>
                    <div class="advanced">
                        <div>
                            Validate against:
                            <div id="catalogs-selector"></div>
                        </div>
                        <div id="addSchema">
                            add Schema (.xsd .dtd): <input type="text" id="newSchema"></input>
                        </div>
                    </div>
                </div>
                <!--
                <div>
                    <input type="checkbox" id="displayPreview" />display preview after processing
                </div>
                -->
                <div>
                    <div id="actionButtons">
<!--                        <select id="previewSelector" class="advanced debug"></select> -->
<!--                        <button type="button" id="generatePreview" disabled="disabled">display preview</button> -->
                        <button id="doAll" type="button" disabled="disabled" class="simple">generate XML</button>
                        <button id="validate" type="button" disabled="disabled" class="advanced">validate</button>
                        <button id="download" type="button" disabled="disabled">download</button>
                    </div>
                </div>
            </div>
            <div class="centered toggleelement" style="cursor:pointer" onclick="$('#menu').slideToggle(300)">
                <span>&#8613;&#8615;</span>
            </div>
            <div>
                <div>
                    <button type="button" onclick="window.open('full-preview.xq')">open full preview</button>
                </div>
                <div class="result-pagination"></div>
                <div id="result-container">
                    <div id="content" style="font-size:10px;">
                </div>
            </div>
            </div>
        </body>
    </html>