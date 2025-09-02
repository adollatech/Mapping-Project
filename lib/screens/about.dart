import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

class About extends StatelessWidget {
  const About({super.key});
  final info =
      "Intelligent Land Mapping & Parcel Management LatTrace is a smart geospatial platform built to digitally map, trace, and manage land parcels with precision and transparency. Designed for governments, communities, planners, and developers, LatTrace enables secure access to land ownership data, boundaries, and planning insights — all from an interactive digital map.";
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Center(
      child: SingleChildScrollView(
        child: ShadCard(
          width: 360,
          child: FutureBuilder(
              future: PackageInfo.fromPlatform(),
              builder: (context, snap) {
                if (!snap.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }
                final packageInfo = snap.requireData;
                return Column(
                  spacing: 16,
                  children: <Widget>[
                    CircleAvatar(
                      backgroundColor: Colors.white10,
                      child: Icon(Icons.map_rounded),
                    ),
                    Text(
                      packageInfo.appName,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 18.0),
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      "Version ${packageInfo.version}",
                      style: const TextStyle(fontSize: 16.0),
                      textAlign: TextAlign.center,
                    ),
                    Text("${packageInfo.appName} $info",
                        style: const TextStyle(fontSize: 16.0)),
                    const Padding(
                        padding: EdgeInsets.symmetric(
                            vertical: 12.0, horizontal: 8.0),
                        child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text("With ",
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                              Icon(
                                Icons.favorite,
                                color: Colors.pink,
                              ),
                              Text(" from Adolla Tech",
                                  style: TextStyle(fontWeight: FontWeight.bold))
                            ])),
                    ShadButton.ghost(
                      trailing: const Icon(Icons.close),
                      onPressed: () {
                        context.pop();
                      },
                      child: Text('Close'),
                    )
                  ],
                );
              }),
        ),
      ),
    ));
  }
}
