<?
	header('Content-type: text/plain');


	$data = file_get_contents('jquery-1.4.2.min.js');

	echo "len: ".strlen($data)."\n";

	$chars = array();
	for ($i=0; $i<strlen($data); $i++){
		$chars[ord(substr($data, $i, 1))]++;
	}

	for ($i=0; $i<256; $i++){
		$c = intval($chars[$i]);
		$ix = sprintf('%02x', $i);
		echo "$ix: $c\n";
	}

?>