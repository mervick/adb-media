<?php


$home = '/home/' . get_current_user();
$rhythmboxDB = $home . '/.local/share/rhythmbox/rhythmdb.xml';

if (!file_exists($rhythmboxDB))
    exit(1);

$xml = file_get_contents($rhythmboxDB);

$artistRe = preg_quote($argv[1] ?? '', '/');
$titleRe = preg_quote($argv[2] ?? '', '/');

$debug = ($argv[3] ?? '') === '--debug';

$reg1 = '<entry type="song">(?:(?!<\/entry>).)*' .
        '<title>(' . $titleRe . ')<\/title>(?:(?!<\/entry>).)*' .
        '<artist>(' . $artistRe . ')<\/artist>(?:(?!<\/entry>).)*' .
        '<album>((?:(?!<\/album>).)*)<\/album>(?:(?!<\/entry>).)*';

$reg2 = $reg1 . '<album\-artist>((?:(?!<\/album\-artist>).)*)<\/album\-artist>';

foreach ([$reg2, $reg1] as $regexp) {
    if (preg_match('/' . $regexp. '/isSX', $xml, $m)) {
        list(, $title, $artist, $album) = $m;
        $albumArtist = $m[4] ?? $artist;

        if ($debug) {
            unset($m[0]);
            print_r($m);
        }

        echo $title, PHP_EOL;
        echo $artist, PHP_EOL;
        echo $album, PHP_EOL;

        $albumPath = $home . '/.cache/rhythmbox/album-art';
        $albumDB = $albumPath . '/store.tdb';

        if (!file_exists($albumDB))
            exit(2);

        $db = file_get_contents($albumDB);

        $str = function($str) {
            return str_replace(' ', '\s', preg_quote($str, '/'));
        };

        $hex = function($hex) {
            return implode('', array_map(function($hex) {return "[\x$hex]";}, explode(' ', $hex)));
        };

        if (preg_match('/' .
            $hex('19 01 26') .
            'album' . $hex('00') . $str($album) . $hex('00') .
            'artist' . $hex('00'). $str($albumArtist) . $hex('00') .
            '[^¤]*?'. $hex('00') .
            'file'. $hex('00 00 00 00 2E 2F') . '([^\x00]+)' . $hex('00') .
            '/iSX', $db, $m)) {
            $art = $m[1];

            if ($debug) {
                unset($m[0]);
                print_r($m);
            }
            echo $albumPath . '/' . $art, PHP_EOL;
        }

        exit;
    }
}

exit(3);
