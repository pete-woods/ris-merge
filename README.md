# RIS merge and de-duplication tool

Simple tool to merge and de-duplicate RefMan (RIS) bibiographical
export files based on fuzzy title (or other field) matching.

## Dependencies
This tool only uses core Ruby modules, and should work with any
modern installation of Ruby. It has only been tested on macOS
and Linux.

## Basic usage
If you have a bunch of input RIS files named, e.g.:

- `input-sourceA.ris`
- `input-sourceB.ris`
- `input-sourceC.ris`

you can merge them as follows:
```
./ris-merge.rb -o merged.ris input-*.ris
```

## Specify which fields to merge on
If one or more of your sources uses e.g. a non-standard title field,
you can override the default fields with the `-f` switch:

```
./ris-merge.rb -f T1 -f TI -o merged-custom-fields.ris input-*.ris
```

## Verbose statistics
If you need details about how many references came from each of your
inputs, how many references were de-duplicated, then the `-v` switch
is what you need:

```
./ris-merge.rb -v -o merged.ris input-*.ris
```

## Chunked output
Many tools that handle the RefMan format struggle to ingest too many
references at once (e.g. EndNote Web), so this tool can chunk the
output into separate files to be uploaded separately.

1000 is a good value for EndNode Web.

```
./ris-merge.rb -c 1000 -o merged-chunked.ris input-*.ris
```

This will write output to:

- `merged-chunked-0.ris`
- `merged-chunked-1.ris`
- `merged-chunked-2.ris`
- etc

## Putting it all together
All the options can be combined together:
```
./ris-merge.rb -f T1 -f TI -c 1000 -v -o merged-chunked.ris input-*.ris
```