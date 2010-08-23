<?
	header('Content-type: text/plain');

	$GLOBALS[path] = 'test_images/';



	encode_file('lipsum.txt', 'lipsum');
	encode_file('jquery-1.4.2.min.js', 'jquery');


	####################################################################################################

	function encode_file($path, $prefix){

		$data = file_get_contents($path);
		$size = strlen($data);

		echo "$path is $size bytes\n";


		#
		# the simplest method is to store the bytes as they are in ascii.
		# this is the least space-efficient.
		#

		$bytes = array();
		for ($i=0; $i<strlen($data); $i++){
			$bytes[] = ord(substr($data, $i, 1));
		}

		store_bytes($bytes, $prefix.'_ascii');


		#
		# next simplest is to store values using 7 bits, so we store 8
		# characters in every 7 bytes
		#
		# 11111112 22222233 33333444 44445555 55566666 66777777 78888888
		#

		$bytes = array();
		$seqs = ceil(strlen($data) / 8);
		for ($i=0; $i<$seqs; $i++){

			$c1 = ord(substr($data, ($i*8)+0, 1));
			$c2 = ord(substr($data, ($i*8)+1, 1));
			$c3 = ord(substr($data, ($i*8)+2, 1));
			$c4 = ord(substr($data, ($i*8)+3, 1));
			$c5 = ord(substr($data, ($i*8)+4, 1));
			$c6 = ord(substr($data, ($i*8)+5, 1));
			$c7 = ord(substr($data, ($i*8)+6, 1));
			$c8 = ord(substr($data, ($i*8)+7, 1));

			$b1 = (($c1 << 1) | ($c2 >> 6)) & 0xff;
			$b2 = (($c2 << 2) | ($c3 >> 5)) & 0xff;
			$b3 = (($c3 << 3) | ($c4 >> 4)) & 0xff;
			$b4 = (($c4 << 4) | ($c5 >> 3)) & 0xff;
			$b5 = (($c5 << 5) | ($c6 >> 2)) & 0xff;
			$b6 = (($c6 << 6) | ($c7 >> 1)) & 0xff;
			$b7 = ((($c7 << 7) & 0x80) | ($c8 & 0x7f)) & 0xff;

			$bytes[] = $b1;
			$bytes[] = $b2;
				$bytes[] = $b3;
			$bytes[] = $b4;
			$bytes[] = $b5;
			$bytes[] = $b6;
			$bytes[] = $b7;
		}

		store_bytes($bytes, $prefix.'_seq8');
	}

	####################################################################################################

	function store_bytes($bytes, $mode){

		$size = count($bytes);


		#
		# 8b
		#

		$w = floor(sqrt($size));
		$h = ceil($size / $w);

		create_8b($mode, 'wide',	$bytes, $size,	1);
		create_8b($mode, 'tall',	$bytes, 1,	$size);
		create_8b($mode, 'square',	$bytes, $w,	$h);


		#
		# 24b
		#

		$px = ceil($size / 3);

		$w = floor(sqrt($px));
		$h = ceil($px / $w);

		create_24b($mode, 'wide',	$bytes, $px,	1);
		create_24b($mode, 'tall',	$bytes, 1,	$px);
		create_24b($mode, 'square',	$bytes, $w,	$h);



		#
		# 32b
		#

		$px = ceil($size / 4);

		$w = floor(sqrt($px));
		$h = ceil($px / $w);

		create_32b($mode, 'wide',	$bytes, $px,	1);
		create_32b($mode, 'tall',	$bytes, 1,	$px);
		create_32b($mode, 'square',	$bytes,	$w,	$h);
	}

	####################################################################################################

	function create_8b($mode, $shape, $bytes, $w, $h){

		$im = imagecreate($w, $h);

		$cols = array();
		for ($i=0; $i<256; $i++){
			$cols[$i] = imagecolorallocate($im, $i, 0, 0);
		}

		$i=0;
		for ($y=0; $y<$h; $y++){
		for ($x=0; $x<$w; $x++){

			$b1 = intval($bytes[$i]);

			$col = $cols[$b1];

			imagesetpixel($im, $x, $y, $col);

			$i++;
		}
		}

		imagepng($im, $GLOBALS[path]."{$mode}_8b_{$shape}.png", 9);
		imagedestroy($im);
	}

	####################################################################################################

	function create_24b($mode, $shape, $bytes, $w, $h){

		$im = imagecreatetruecolor($w, $h);
		imageAlphaBlending($im, false);
		imageSaveAlpha($im, false);

		$i=0;
		for ($y=0; $y<$h; $y++){
		for ($x=0; $x<$w; $x++){

			$b1 = $bytes[($i*3)+0];
			$b2 = $bytes[($i*3)+1];
			$b3 = $bytes[($i*3)+2];

			$col = imagecolorallocate($im, $b1, $b2, $b3);

			imagesetpixel($im, $x, $y, $col);

			$i++;
		}
		}

		imagepng($im, $GLOBALS[path]."{$mode}_24b_{$shape}.png", 9);
		imagedestroy($im);
	}

	####################################################################################################

	function create_32b($mode, $shape, $bytes, $w, $h){

		$im = imagecreatetruecolor($w, $h);
		imageAlphaBlending($im, false);
		imageSaveAlpha($im, true);

		$i=0;
		for ($y=0; $y<$h; $y++){
		for ($x=0; $x<$w; $x++){

			$b1 = $bytes[($i*4)+0];
			$b2 = $bytes[($i*4)+1];
			$b3 = $bytes[($i*4)+2];
			$b4 = $bytes[($i*4)+3];

			$col = imagecolorallocatealpha($im, $b1, $b2, $b3, $b4);

			#echo "$b1, $b2, $b3, $b4 ..";

			imagesetpixel($im, $x, $y, $col);

			$i++;
		}
		}

		imagepng($im, $GLOBALS[path]."{$mode}_32b_{$shape}.png", 9);
		imagedestroy($im);		
	}

	####################################################################################################
?>