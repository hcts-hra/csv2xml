xquery version "3.0";

import module namespace csv="http://hra.uni-heidelberg.de/ns/hra-csv2vra/csv" at "modules/csv.xqm";
import module namespace response="http://exist-db.org/xquery/response";


declare namespace xhtml="http://www.w3.org/1999/xhtml";


let $file-name := request:get-uploaded-file-name('file')
let $file-data := request:get-uploaded-file-data('file')

let $fileinfo := contentextraction:get-metadata($file-data)
let $filetype := substring-before(data($fileinfo//xhtml:meta[@name="Content-Type"]/@content), ";")
let $file-encoding := $fileinfo//xhtml:meta[@name="Content-Encoding"]/@content/string()
let $filetype := "text/plain"

(: check format :)
return
    switch ($filetype)
        case "text/plain" return
            try {
                let $csv-string := util:binary-to-string($file-data, $file-encoding)
                let $csv-parsed := csv:read-csv($csv-string)
                let $csv-data := csv:add-char-index($csv-parsed)
                let $useless := session:set-attribute("data", $csv-data)
                let $header := response:set-header("Status", "200")
                let $parameters :=     
                    <output:serialization-parameters xmlns:output="http://www.w3.org/2010/xslt-xquery-serialization">
                        <output:method value="json"/>
                        <output:media-type value="text/javascript"/>
                        <output:prefix-attributes value="yes"/>
                    </output:serialization-parameters>
    (:            let $useless := util:log("DEBUG", $self-id-url || " " || $remote-id-url):)
                let $header := response:set-header("Content-Type", "application/json")
(:                let $log := util:log("INFO", $csv-data):)

                let $result :=
                    <info>
                        <lines>{count($csv-data/line)}</lines>
                    </info>
                return
                    serialize($result, $parameters)
            } catch * {
                let $header := response:set-header("Status", "400")
                return
                    "uploading or parsing csv failed"
            }
        default return
            let $header := response:set-header("Status", "400")
            return
                <div>Fileformat not supported!</div>
