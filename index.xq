xquery version "3.0";

declare namespace output="http://www.w3.org/2010/xslt-xquery-serialization";

declare option output:method "html5";
declare option output:media-type "text/html";

<html>
    <body>
        <div xmlns="http://www.w3.org/1999/xhtml" data-template="templates:surround" data-template-with="templates/page.html" data-template-at="content">
            <div class="col-md-12">
                <div class="page-header">
                    <h1>CSV2VRA</h1>
                </div>
                <div>
                    <form role="form" enctype="multipart/form-data" method="post" action="upload.xq">
                        <div class="form-group">
                            <label for="inputFile">Choose CSV to upload</label>
                            <input type="file" id="inputFile" name="file"/>
                        </div>
                        <button type="submit" class="btn btn-default">Proceed &gt;&gt;</button>
                    </form>
                </div>
            </div>
        </div>
    </body>
</html>