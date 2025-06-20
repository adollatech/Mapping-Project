import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

class About extends StatelessWidget {
  const About({super.key});
  final info = "Intelligent Land Mapping & Parcel Management LatTrace is a smart geospatial platform built to digitally map, trace, and manage land parcels with precision and transparency. Designed for governments, communities, planners, and developers, LatTrace enables secure access to land ownership data, boundaries, and planning insights — all from an interactive digital map.";
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            Navigator.pop(context);
          },
        )),
        body: FutureBuilder(
            future: PackageInfo.fromPlatform(),
            builder: (context, snap) {
              if (!snap.hasData) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }
              final packageInfo = snap.requireData;
              return ListView(
                padding: const EdgeInsets.all(16.0),
                children: <Widget>[
                  const Align(
                      alignment: Alignment.topCenter,
                      child: SizedBox(
                        height: 60,
                        width: 60,
                        child: CircleAvatar(
                          backgroundColor: Colors.white10,
                          child: Icon(Icons.map_rounded),
                        ),
                      )),
                  const SizedBox(height: 12,),
                  Text(
                    packageInfo.appName,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 18.0),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12,),
                  Text(
                    "Version ${packageInfo.version}",
                    style: const TextStyle(fontSize: 16.0),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12,),
                  Text("${packageInfo.appName} $info",
                      style: const TextStyle(fontSize: 16.0)),
                  const Spacer(
                    flex: 4,
                  ),
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
                          ]))
                ],
              );
            }));
  }
}
