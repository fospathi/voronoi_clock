import 'package:flutter/painting.dart';
import 'package:test/test.dart';
import 'package:voronoi_clock/src/delaunay_triangulation.dart';

import 'package:voronoi_clock/src/voronoi_diagram.dart';

void main() {
  test("NeighbourSeed.compareTo() sorts in an anticlockwise direction", () {
    final principal = Seed(Offset(10, 10));
    final sortMe = <NeighbourSeed>[
      NeighbourSeed(Seed(Offset(15, 15)), principal),
      NeighbourSeed(Seed(Offset(5, 15)), principal),
      NeighbourSeed(Seed(Offset(5, 5)), principal),
      NeighbourSeed(Seed(Offset(15, 5)), principal),
    ];
    final sorted = sortMe.toList()..sort();
    expect(
        sorted,
        equals(<Seed>[
          Seed(Offset(5, 5)),
          Seed(Offset(15, 5)),
          Seed(Offset(15, 15)),
          Seed(Offset(5, 15)),
        ]));
  });

  test("VoronoiDiagram.neighbourSeeds() get the neighbours of a cell", () {
    final principal = Seed(Offset(10, 10));
    final seeds = <Seed>[
      Seed(Offset(10, 10)),
      Seed(Offset(15, 15)),
      Seed(Offset(5, 15)),
      Seed(Offset(5, 5)),
      Seed(Offset(15, 5)),
      Seed(Offset(6, 10)),
      Seed(Offset(20, 10)),
      Seed(Offset(10, 20)),
      Seed(Offset(0, 10)),
      Seed(Offset(10, -10)),
    ];
    final triangulation = DelaunayTriangulation.bowyerWatson(
        seeds.map((seed) => seed.toPoint()).toSet());
    final neighbours =
        VoronoiDiagram.neighbourSeeds(triangulation, principal, seeds.toSet());

    expect(
        neighbours,
        equals(<Seed>[
          Seed(Offset(6.0, 10.0)),
          Seed(Offset(5.0, 5.0)),
          Seed(Offset(15.0, 5.0)),
          Seed(Offset(20.0, 10.0)), // Cells touch at a single point only.
          Seed(Offset(15.0, 15.0)),
          Seed(Offset(10.0, 20.0)), // Cells touch at a single point only.
          Seed(Offset(5.0, 15.0))
        ]));
  });
}
