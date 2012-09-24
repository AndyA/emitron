<?php
// Dummy php to force download the xml file
header('Content-disposition: attachment; filename=streams.xml');
header('Content-type: streams');
readfile('../shared/streams.xml');