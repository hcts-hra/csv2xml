xquery version "3.0";
declare namespace output="http://www.w3.org/2010/xslt-xquery-serialization";

declare option output:method "html5";
declare option output:media-type "text/html";

let $data := session:get-attribute("data")
let $parsed-csv := session:get-attribute("parsed-csv")

return 
    <html>
        <head>
            <title>CSV2XML - Debug Output</title>
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
            <script type="text/javascript">
                $(document).ready(function() {{
                    prettyPrint();
                }});
            </script>
            <style type="text/css">
                .hidden{{
                    display:none;
                }}
            </style>
        </head>
        <body>
            <div style="font-size:10px;">
                <xmp class="prettyprint linenums">
                    {$parsed-csv}
                </xmp>
            </div>
            <div id="content" style="font-size:10px;">
                <xmp class="prettyprint linenums">
                    {$data}
                </xmp>
            </div>
        </body>
    </html>