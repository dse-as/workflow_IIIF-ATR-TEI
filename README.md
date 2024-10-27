# ⚙️ Workflow IIIF-ATR-TEI

Scripts for Transkribus-related workflows:

* generation of IIIF manifests, see https://github.com/dse-as/i3f
* upload IIIF manifest to Transkribus
* download PAGE XML from Transkribus
* transform PAGE XML from Transkribus to raw TEI
* transform raw TEI to final format

## Upload IIIF images to Transkribus for ATR

[![Initiate IIIF upload to Transkribus](assets/image.png)](https://github.com/dse-as/workflow_IIIF-ATR-TEI/issues/new/choose)

Automated upload workflow of IIIF images into a Transkribus collection.

---

## Download PAGE

```bash
python scripts/PAGE-from-Transkribus/download_latest_pagexml.py -u 'USERNAME' -p 'PASSWORD' -c 'COLLECTION-ID-1' 'COLLECTION-ID-2' -o 'OUTFOLDER'
```

## PAGE to raw TEI

```bash
python scripts/PAGE-to-raw-TEI/page2TEI.py -i download -o download_out
```

## Acknowledgement

The code in this repository is based on 

* [history-unibas/Trankribus-API](https://github.com/history-unibas/Trankribus-API)
* [raykyn/page2tei](https://github.com/raykyn/page2tei)

## License

* [dse-as/workflow_IIIF-ATR-TEI](https://github.com/dse-as/workflow_IIIF-ATR-TEI): See [LICENSE](LICENSE)
