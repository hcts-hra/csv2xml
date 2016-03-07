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
            <title>VRA Core 4 XML Transform Tool</title>
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
            <div id="header">VRA Core 4 XML Transform Tool</div>
            <div id="log-dialog" class="log"></div>
            <div id="git-version">App-Version: <span>{$local:app-version}</span></div>
            <div>
                <button id="reset" type="button">Reset</button>
                <button id="toggle-log" type="button">Toggle log</button>
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
                <div style="float:right" id="header-line">
                    <input type="checkbox" id="advancedMode" />Advanced Mode
                </div>
                <div>
                    <div id="upload-mask">
                        <form id="csv-upload" enctype="multipart/form-data" method="post" action="upload.xq">
                            <div id="header-line">Upload CSV</div>
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
                        <div id="header-line">Transform CSV</div>
                        <span class="indent">
                            Process lines <input type="text" id="process-from" value="1" size="3em"/> to <input class="lines-amount" type="text" id="process-to" value="{count($data/line)}" size="3em"/>
                        </span>
                    </div>
                    <div>
                        <span class="indent">Apply mapping </span>
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
                        <button id="generate" class="advanced" type="button" disabled="disabled">Generate XML</button>
                    </div>
                    <div>
                        <span class="indent">Transform using preset </span>
                        <select id="transformations-selector">
                        </select>
                    </div>
                    <div class="advanced">
                        <span class="indent">Apply XSLs (for transformation): </span>
                        <div id="xsl-selector"></div>
                        <div style="font-size:8px">(modifying the predefined selection may break pagination)</div>
                    </div>
                    <div>
                        <button id="applyXSL" class="advanced" type="button" disabled="disabled">Transform XML</button>
                    </div>
                    <div class="advanced">
                        <div>
                            <span class="indent">Validate against: </span>
                            <div id="catalogs-selector"></div>
                        </div>
                        <div id="addSchema">
                            <span class="indent">Add Schema (.xsd .dtd): </span><input type="text" id="newSchema"></input>
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
                        <button id="doAll" type="button" disabled="disabled" class="simple">Generate XML</button>
                        <button id="validate" type="button" disabled="disabled" class="advanced">Validate</button>
                        <button id="download" type="button" disabled="disabled">Download</button>
                    </div>
                </div>
            </div>
            <div class="centered toggleelement" style="cursor:pointer" onclick="$('#menu').slideToggle(300)">
                <span>&#8613;&#8615;</span>
            </div>
            <div>
                <div>
                    <button type="button" onclick="window.open('full-preview.xq')">Open full preview</button>
                </div>
                <div class="result-pagination"></div>
                <div id="result-container">
                    <div id="content" style="font-size:10px;">
                </div>
            </div>
            </div>
            <div id="footer">
            <p>The VRA Core 4 XML Transform Tool is open-source software and can be used freely. For <b>user documentation, .csv templates, and a set of sample records</b> please refer to the <a href="https://github.com/exc-asia-and-europe/csv2xml/tree/master/doc">documentation folder on GitHub</a>. You may also <a href="https://github.com/exc-asia-and-europe/csv2xml">download the source code</a> there. If you are happy using the tool or wish to provide feedback, please <a href="mailto:hra@asia-europe.uni-heidelberg.de?subject=Feedback VRA Core 4 XML Transform Tool">drop us a line</a>.</p>
            <p>Development of the tool was generously supported by the <a href="http://vrafoundation.org/index.php/home/">Visual Resources Association Foundation (VRAF)</a> and the <a href="http://hra.uni-hd.de/">Heidelberg Research Architecture</a> at <a href="http://www.asia-europe.uni-heidelberg.de/en/hcts.html">Heidelberg Centre for Transcultural Studies</a>, University of Heidelberg.</p>
            <p><a href="http://vrafoundation.org/index.php/home/"><img src="../csv2xml/resources/images/VRAF_small.png" alt="VRAF logo" width="100px"/></a> <a href="http://www.asia-europe.uni-heidelberg.de/en/hcts.html"><img src="../csv2xml/resources/images/HCTS_small.png" alt="HCTS logo" width="160px"/></a> </p>
            </div>
        </body>
    </html>