import 'dart:async';

import 'package:flutter/material.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:surveyapp/services/auth_service.dart';
import 'package:surveyapp/utils/utils.dart';
import 'package:surveyapp/widgets/loading_widget.dart';

class CustomStreamBuilder<T> extends StatefulWidget {
  final String collection;
  final T Function(Map<String, dynamic>) fromMap;
  final Widget Function(BuildContext context, List<T> data) builder;
  final String topic;
  final String? filter;
  final int? limit;
  final Widget? loader;
  final Widget Function(Object? error)? onError;
  final Widget Function()? onEmpty;
  final String? sort;

  const CustomStreamBuilder({
    super.key,
    required this.collection,
    required this.fromMap,
    required this.builder,
    this.filter,
    this.limit,
    this.sort,
    this.topic = "*",
    this.loader,
    this.onError,
    this.onEmpty,
  });

  @override
  State<CustomStreamBuilder<T>> createState() => _CustomStreamBuilderState<T>();
}

class _CustomStreamBuilderState<T> extends State<CustomStreamBuilder<T>> {
  final _streamController = StreamController<List<T>>.broadcast();
  UnsubscribeFunc? _unsubscribe;

  @override
  void initState() {
    super.initState();
    _fetchInitialData();
    _setupRealtimeListener();
  }

  Future<void> _fetchInitialData() async {
    try {
      final result = await pb.collection(widget.collection).getList(
            page: 1,
            perPage: widget.limit ?? 50,
            filter: widget.filter,
            sort: widget.sort,
          );

      final data =
          result.items.map((record) => widget.fromMap(record.data)).toList();
      _streamController.sink.add(data);
    } on ClientException catch (e) {
      final message = e.response['message'] ?? 'Something went wrong';
      if (mounted) {
        showSnackBar(context, message, error: true);
      }
    }
  }

  void _setupRealtimeListener() async {
    _unsubscribe =
        await pb.collection(widget.collection).subscribe(widget.topic, (event) {
      _fetchInitialData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<T>>(
      stream: _streamController.stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return widget.loader ??
              LoadingWidget(
                width: double.infinity,
                height: MediaQuery.of(context).size.height * 0.5,
              );
        }
        if (snapshot.hasError) {
          if (widget.onError != null) {
            return widget.onError!(snapshot.error);
          }
          return Center(
            child:
                Text("Failed to get ${widget.collection.split("_").join(" ")}"),
          );
        }
        if (!snapshot.hasData || snapshot.data == null) {
          if (widget.onEmpty != null) {
            return widget.onEmpty!();
          }
          return Center(
            child: Text("You have no ${widget.collection} yet"),
          );
        }
        return widget.builder(context, snapshot.data!);
      },
    );
  }

  @override
  void dispose() {
    _unsubscribe?.call();
    _streamController.close();
    super.dispose();
  }
}
