xquery version "3.0";

module namespace csv="http://hra.uni-heidelberg.de/ns/hra-csv2vra/csv";
import module namespace functx="http://www.functx.com";

declare function csv:split-line($str)
{
    if (fn:starts-with($str, '"')) then
        let $rest := fn:substring($str, 2)
        return 
        (
            fn:substring-before($rest, '"'),
            csv:split-line(fn:substring-after($rest, '",'))
        )
    else if (fn:matches($str, ",")) then 
        (
            fn:substring-before($str, ','),
            csv:split-line(fn:substring-after($str, ','))
        )
    else 
        $str
};


declare function csv:num-to-char($num as xs:int) {
    let $num := $num - 1
    let $rounds := floor($num div 26)
    return 
        if($rounds > 0) then
            codepoints-to-string(64 + $rounds) || csv:num-to-char(($num mod 26) + 1)
        else
            codepoints-to-string(65 + $num)
};


declare
(:    %templates:wrap:)
function csv:read-csv($csv-string as xs:string) {
    let $lines := tokenize($csv-string, "\n")
    let $head := tokenize($lines[1], ',')
(:    let $body := remove($lines, 1):)
    let $body := $lines
    return 
      <result>
            {
                for $line at $lpos in $body
                    let $columns := csv:split-line($line)
                    return
                        <line num-index="{$lpos}">
                            {
                                for $column at $pos in $columns
                                return
                                    <column num-index="{$pos}">
                                        {
                                            functx:trim($column)
                                        }
                                    </column>
                            }
                        </line>
            }
        </result>
};

declare function csv:add-char-index($csv-data as node()*) {
    let $output :=
        <csv>
            {
                for $line in $csv-data//line
                let $line-num-index := data($line/@num-index)
                    return
                        <line num-index="{$line-num-index}">
                        {
                            for $column in $line/column
                            let $column-num-index := data($column/@num-index)
                                return
                                    <column num-index="{$column-num-index}" char-index="{csv:num-to-char(xs:integer($column-num-index))}">
                                        {
                                            data($column)
                                        }
                                    </column>
                        }
                        </line>
            }
        </csv>
    return 
        $output
};
