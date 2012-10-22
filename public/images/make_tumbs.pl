#!/usr/bin/perl -w

`mkdir thumbs` unless -d "thumbs";

@pix = `ls *.jpg *.JPG *.jpeg *.JPEG *.gif *.GIF`;

for $pix (@pix) {
    chomp $pix;
    my ($name, $ending) = split('\.', $pix);
    $name = join('', 'thumb_', $name);

    print "$pix -> $name.jpg \n";
    `convert $pix -thumbnail x200 -resize '200x<' -resize 50% -gravity center -crop 100x100+0+0 +repage -format jpg -quality 91 thumbs/$name.$ending`;
}
