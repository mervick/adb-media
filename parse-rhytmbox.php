<?php


$home = '/home/' . get_current_user();
$rhythmboxDB = $home . '/.local/share/rhythmbox/rhythmdb.xml';

if (!file_exists($rhythmboxDB))
    exit(1);

$xml = file_get_contents($rhythmboxDB);

$artistRe = preg_quote($argv[1] ?? '', '/');
$titleRe = preg_quote($argv[2] ?? '', '/');

if (preg_match('/' .
    '<entry type="song">(?:(?!<\/entry>).)*' .
    '<title>(' . $titleRe . ')<\/title>(?:(?!<\/entry>).)*' .
    '<artist>(' . $artistRe . ')<\/artist>(?:(?!<\/entry>).)*' .
    '<album>((?:(?!<\/album>).)*)<\/album>' .
    '/isSX', $xml, $m)) {
    list(, $title, $artist, $album) = $m;

    echo $title, PHP_EOL;
    echo $artist, PHP_EOL;
    echo $album, PHP_EOL;

    $albumPath = $home . '/.cache/rhythmbox/album-art';
    $albumDB = $albumPath . '/store.tdb';

    if (!file_exists($albumDB))
        exit(2);

    $db = file_get_contents($albumDB);

    $artistRe = preg_quote($artist, '/');
    $albumRe = preg_quote($album, '/');

    if (preg_match('/' .
        '[\x19][\x01][\x26]album[\x00]' . $albumRe .
        '[\x00]artist[\x00]' . $artistRe . '[\x00](?:(?!file).)*[\x00]{3}file[\x00]{4}[\x2e][\x2f]([^\x00]+)[\x00]' .
        '/', $db, $m)) {
        $art = $m[1];

        echo $albumPath . '/' . $art, PHP_EOL;
    }
} else {
    exit(3);
}
