# ⚙️ DSE-AS document workflow: IIIF-ATR-TEI

Scripts for Transkribus-related workflows:

* generation of IIIF manifests, see https://github.com/dse-as/i3f
* upload IIIF manifest to Transkribus
* delete documents from a Transkribus collection
* download PAGE XML from Transkribus
* transform PAGE XML from Transkribus to raw TEI
* transform raw TEI to final format

## Upload IIIF images to Transkribus for ATR

[![Initiate IIIF upload to Transkribus](assets/iiif-upload.png)](https://github.com/dse-as/workflow_IIIF-ATR-TEI/issues/new/choose)

Automated upload workflow of IIIF images into a Transkribus collection.

## Delete documents from Transkribus collection

[![Delete Transkribus document](assets/doc-deletion.png)](https://github.com/dse-as/workflow_IIIF-ATR-TEI/issues/new/choose)

---

## Download PAGE

```bash
python scripts/PAGE-from-Transkribus/download_latest_pagexml.py -u 'USERNAME' -p 'PASSWORD' -c 'COLLECTION-ID-1' 'COLLECTION-ID-2' -o 'OUTFOLDER'
```

## PAGE to raw TEI

```bash
python scripts/PAGE-to-raw-TEI/page2TEI.py -i download -o download_out
```

## Schematic


```
        ───────────────────────────────────────────────────────────────────────────────────────╮
                           document and image identifiers remain stable after initial creation │
                                                                                               │
  ┌─┬──┬─┬─┬──┬──┬─┬──┬─┬─┐                                                                    │
  │small forms   │ │  │ │ │                                                                    │
  │ID  │metadata      IIIF│                                                                    │
  │ │ ┌┴┬──┬─┬─┬──┬──┬─┬──┼─┬─┐                   iiif.annemarie-schwarzenbach.ch/presentation │
  │ │ │letters       │ │  │ │ │                                                                │
  │ │ │ID  │metadata      IIIF│                     ┌─────┐                                    │
  │ │ │ │  │ │ │  │  │ │  │ │ │   ━━━━━━━━━━━━━━▶  ┌┴────┐│    one .toml file per document     │
  └─┴─┤ │  │ │ │  │  │ │  │ │ │                   ┌┴────┐││                                    │
      │ │  │ │ │  │  │ │  │ │ │                   │     │├┘                                    │
      │ │  │ │ │  │  │ │  │ │ │                   │     ├┘                                     │
      └─┴──┴─┴─┴──┴──┴─┴──┴─┴─┘                   └─────┘                                      │
  docs.google.com/spreadsheets                           commit to dse-as.github.io/i3f        │
                                                      generates IIIF presentation manifest     │
                                                                                               │
                                                                          ┃                    │
                                                                          ┃                    │
                                                                          ┃                    │
                                                                          ┃                    │
                                                                          ┃                    │
                                                                          ▼                    │
                                                                                               │
                                                  dse-as.github.io/workflow_IIIF-Transkribus-AT│
┌────────────────────────────┐                                                ┌─────────────┐  │
│ ┌──────────┐ ═══════════   │                                                │             │  │
│ │          │ ══════════    │                       form-based image upload  ├─────────────┤  │
│ │          │ ═══════════   │    ◀━━━━━━━━━━━━━━       into Transkribus      │─────        │  │
│ │          │ ═════════════ │                             collection         │─────        │  │
│ │          │ ═══════════   │                                                ├─────────────┤  │
│ │          │ ═════════════ │                                                └─────────────┘  │
│ │          │ ═══════════   │                                                                 │
│ └──────────┘ ══════════    │                                                                 │
│                            │                                                                 │
│                            │                                                                 ▼
└────────────────────────────┘                                                                 │
 app.transkribus.org                                                                           │
                                                                                               │
 text recognition, (rough) structural annotation                                               │
                                                                                               │
  ┃                                                                                            │
  ┃                                                                                            │
  ┃   3 Transkribus collections                                                                │
  ┃                                                                                            │
  ┃                                                                                            │
  ┗━━━━▶  as-dse_wait                                                                          │
      ┃                                                                                        │
      ┃                                                                                        │
      ┃                                                                                        │
      ┃                                                                                        │
      ┃                                                                                        │
      ┗━━━━▶  as-dse_work                                                                      │
          ┃                                                  TEI-XML data                      │
          ┃                                                                                    │
          ┃                                                  ┌───────┐                         │
          ┃                                                  │       ├─┐                       │
          ┃                                                  │       │ ├─┐  1 file per text    │
          ┗━━━━▶  as-dse_finalised     ━━━━━━━━━━━━━━━▶      │       │ │ │                     │
                                                             │       │ │ │                     │
                                                             └─┬─────┘ │ │                     │
                                                               └─┬─────┘ │                     ▼
                                     script-based export from    └───────┘                      
                                        Transkribus and data          ║                         
                                      transformation (raw TEI,        ║                         
                                            project TEI)         ╔════╩════════════════╗        
                                                                 ║                     ║        
                                                                 ║                     ║        
                                                                 ║                     ║        
                                                                 ║                     ║        
                                                                 ║                     ║        
                                                                 ║                     ║        
                                                                 ▼                     ▼        
                                                                                                
┌──────────────────────────────────────────────────────────────────────────┐  ┌───────────────┐ 
│                     development of web presentation                      │  │               │ 
│                                                                          │  │  FAIR data    │ 
├────────────────────────┬────────────────────────┬────────────────────────┤  │  repository   │ 
│                        │                        │                        │  │               │ 
│   data transformation, │    index, register     │        frontend        │  │               │ 
│     (static) backend   │                        │                        │  │               │ 
│                        │                        │                        │  │               │ 
└────────────────────────┴────────────────────────┴────────────────────────┘  └───────────────┘ 
```

## Credits

The code in this repository is based on 

* [magbb/transkribus_API_wrapper](https://github.com/magbb/transkribus_API_wrapper/blob/master/transkribus_API_IIIF_NB_pipeline.ipynb)
* [history-unibas/Trankribus-API](https://github.com/history-unibas/Trankribus-API)
* [raykyn/page2tei](https://github.com/raykyn/page2tei)

## License

* [dse-as/workflow_IIIF-ATR-TEI](https://github.com/dse-as/workflow_IIIF-ATR-TEI): See [LICENSE](LICENSE)
