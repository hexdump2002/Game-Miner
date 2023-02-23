import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dialogs/flutter_dialogs.dart';
import 'package:game_miner/logic/blocs/game_mgr_cubit.dart';
import 'package:get_it/get_it.dart';

import '../../data/models/steam_config.dart';
import '../../data/repositories/steam_config_repository.dart';


class AdvancedFilterWidget extends StatefulWidget {
  final AdvancedFilter _advancedFilter;
  final List<String> _searchPaths;

  const AdvancedFilterWidget({Key? key, required AdvancedFilter advancedFilter, required List<String> searchPaths})
      : _advancedFilter = advancedFilter, _searchPaths = searchPaths,
        super(key: key);

  @override
  State<AdvancedFilterWidget> createState() => _AdvancedFilterWidgetState();
}

class _AdvancedFilterWidgetState extends State<AdvancedFilterWidget> {

  @override
  Widget build(BuildContext context) {

    return SingleChildScrollView(
      child: Column(children: [
        Container(
          color: Colors.grey.shade700,
          padding: EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Text(tr("filter_status"), textAlign: TextAlign.start, style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(
                height: 16,
              ),
              Row(
                children: [
                  Tooltip(
                    message: tr("game_status_red_tooltip"),
                    child: Row(
                      children: [
                        Checkbox(
                            value: widget._advancedFilter.showStatusRed,
                            onChanged: (value) {
                              setState(() {
                                widget._advancedFilter.showStatusRed = value!;
                              });
                            }),
                        Container(height: 15, width: 15, color: Colors.red),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
                          child: Text(
                            tr("ad_fil_red_tooltip"),
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Tooltip(
                    message: tr("game_status_orange_tooltip"),
                    child: Row(
                      children: [
                        Checkbox(
                            value: widget._advancedFilter.showStatusOrange,
                            onChanged: (value) {
                              setState(() {
                                widget._advancedFilter.showStatusOrange = value!;
                              });
                            }),
                        Container(height: 15, width: 15, color: Colors.orange),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
                          child: Text(
                            tr("ad_fil_orange_tooltip"),
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Tooltip(
                    message: tr("game_status_green_tooltip"),
                    child: Row(
                      children: [
                        Checkbox(
                            value: widget._advancedFilter.showStatusGreen,
                            onChanged: (value) {
                              setState(() {
                                widget._advancedFilter.showStatusGreen = value!;
                              });
                            }),
                        Container(height: 15, width: 15, color: Colors.green),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
                          child: Text(
                            tr("ad_fil_green_tooltip"),
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Tooltip(
                    message: tr("game_status_blue_tooltip"),
                    child: Row(
                      children: [
                        Checkbox(
                            value: widget._advancedFilter.showStatusBlue,
                            onChanged: (value) {
                              setState(() {
                                widget._advancedFilter.showStatusBlue = value!;
                              });
                            }),
                        Container(height: 15, width: 15, color: Colors.blue.shade200),
                        Padding(
                            padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
                            child: Text(
                              tr("ad_fil_blue_tooltip"),
                              style: const TextStyle(color: Colors.white),
                            )),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Container(
            padding: EdgeInsets.all(8),
            color: Colors.grey.shade700,
            margin: EdgeInsets.fromLTRB(0, 16, 0, 0),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(tr("filter_search_path"), style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(
                    height: 16,
                  ),
                  Column(
                    children: widget._searchPaths
                        .map<ListTile>((e) => ListTile(
                              visualDensity: VisualDensity(horizontal: -4, vertical: -4),
                              title: Text(e),
                              leading: Checkbox(
                                onChanged: (value) {
                                  setState(() {
                                    if(value!) {
                                      widget._advancedFilter.searchPaths.add(e);
                                    }
                                    else
                                    {
                                      widget._advancedFilter.searchPaths.remove(e);
                                    }
                                  });

                                },
                                value: widget._advancedFilter.searchPaths.contains(e),
                              ),
                            ))
                        .toList(),
                  ),
                ],
              ),
            )),
        Container(
            padding: EdgeInsets.all(8),
            color: Colors.grey.shade700,
            margin: EdgeInsets.fromLTRB(0, 16, 0, 0),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(tr("filter_general"), style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(
                height: 16,
              ),
              Padding(
                  padding: const EdgeInsets.fromLTRB(8, 0, 0, 0),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    Row(
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Checkbox(
                                  value: widget._advancedFilter.showErrors == 0,
                                  onChanged: (value) {
                                    setState(() => widget._advancedFilter.showErrors = 0);
                                  }),
                              Expanded(child: Text(tr("filter_with_errors"))),

                            ],
                          ),
                        ),
                        Expanded(
                          child: Row(
                            children: [
                              Checkbox(
                                  value: widget._advancedFilter.showErrors == 1,
                                  onChanged: (value) {
                                    setState(() => widget._advancedFilter.showErrors = 1);
                                  }),
                              Expanded(child: Text(tr("filter_with_no_errors"))),

                            ],
                          ),
                        ),
                        Expanded(
                          child: Row(
                            children: [
                              Checkbox(
                                  value: widget._advancedFilter.showErrors == 2,
                                  onChanged: (value) {
                                    setState(() => widget._advancedFilter.showErrors = 2);
                                  }),
                              Expanded(child: Text(tr("filter_both"))),

                            ],
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Checkbox(
                                  value: widget._advancedFilter.showChanges == 0,
                                  onChanged: (value) {
                                    setState(() => widget._advancedFilter.showChanges = 0);
                                  }),
                              Expanded(child: Text(tr("filter_with_changes"))),

                            ],
                          ),
                        ),
                        Expanded(
                          child: Row(
                            children: [
                              Checkbox(
                                  value: widget._advancedFilter.showChanges == 1,
                                  onChanged: (value) {
                                    setState(() => widget._advancedFilter.showChanges = 1);
                                  }),
                              Expanded(child: Text(tr("filter_with_no_changes"))),

                            ],
                          ),
                        ),
                        Expanded(
                          child: Row(
                            children: [
                              Checkbox(
                                  value: widget._advancedFilter.showChanges == 2,
                                  onChanged: (value) {
                                    setState(() => widget._advancedFilter.showChanges = 2);
                                  }),
                              Expanded(child: Text(tr("filter_both"))),

                            ],
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Checkbox(
                                  value: widget._advancedFilter.showImages == 0,
                                  onChanged: (value) {
                                    setState(() => widget._advancedFilter.showImages = 0);
                                  }),
                              Expanded(child: Text(tr("filter_with_images"))),

                            ],
                          ),
                        ),
                        Expanded(
                          child: Row(
                            children: [
                              Checkbox(
                                  value: widget._advancedFilter.showImages == 1,
                                  onChanged: (value) {
                                    setState(() => widget._advancedFilter.showImages = 1);
                                  }),
                              Expanded(child: Text(tr("filter_with_no_images"))),

                            ],
                          ),
                        ),
                        Expanded(
                          child: Row(
                            children: [
                              Checkbox(
                                  value: widget._advancedFilter.showImages == 2,
                                  onChanged: (value) {
                                    setState(() => widget._advancedFilter.showImages = 2);
                                  }),

                              Expanded(child: Text(tr("filter_both"))),
                            ],
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Checkbox(
                                  value: widget._advancedFilter.showConfiguration == 0,
                                  onChanged: (value) {
                                    setState(() => widget._advancedFilter.showConfiguration = 0);
                                  }),
                              Expanded(child: Text(tr("filter_with_configuration"))),

                            ],
                          ),
                        ),
                        Expanded(
                          child: Row(
                            children: [
                              Checkbox(
                                  value: widget._advancedFilter.showConfiguration == 1,
                                  onChanged: (value) {
                                    setState(() => widget._advancedFilter.showConfiguration = 1);
                                  }),
                              Expanded(child: Text(tr("filter_with_no_configuration"))),

                            ],
                          ),
                        ),
                        Expanded(
                          child: Row(
                            children: [
                              Checkbox(
                                  value: widget._advancedFilter.showConfiguration == 2,
                                  onChanged: (value) {
                                    setState(() => widget._advancedFilter.showConfiguration = 2);
                                  }),
                              Expanded(child: Text(tr("filter_both"))),

                            ],
                          ),
                        ),
                      ],
                    )
                  ]))
            ]))
      ]),
    );
  }
}
