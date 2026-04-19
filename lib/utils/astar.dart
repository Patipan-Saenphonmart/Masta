import 'dart:math';

class AStarNode {
  final int x;
  final int y;
  double gCost = 0;
  double hCost = 0;
  AStarNode? parent;

  AStarNode(this.x, this.y);

  double get fCost => gCost + hCost;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AStarNode &&
          runtimeType == other.runtimeType &&
          x == other.x &&
          y == other.y;

  @override
  int get hashCode => x.hashCode ^ y.hashCode;
}

class AStar {
  /// ค้นหาเส้นทางบนตาราง 2D (Grid)
  /// Return เป็น List ของพิกัดเวกเตอร์ (x, y) ที่เป็นทางเดินที่ต้องไป
  static List<Point<int>> findPath({
    required int startX,
    required int startY,
    required int targetX,
    required int targetY,
    required int gridWidth,
    required int gridHeight,
    required bool Function(int, int) isWalkable,
  }) {
    final startNode = AStarNode(startX, startY);
    final targetNode = AStarNode(targetX, targetY);

    final openSet = <AStarNode>[];
    final openSetMap = <Point<int>, AStarNode>{};
    final closedSet = <Point<int>>{};

    openSet.add(startNode);
    openSetMap[Point(startX, startY)] = startNode;

    while (openSet.isNotEmpty) {
      // หาโหนดที่มี fCost ต่ำสุด
      var currentNode = openSet[0];
      int currentIndex = 0;
      for (int i = 1; i < openSet.length; i++) {
        if (openSet[i].fCost < currentNode.fCost ||
            (openSet[i].fCost == currentNode.fCost &&
                openSet[i].hCost < currentNode.hCost)) {
          currentNode = openSet[i];
          currentIndex = i;
        }
      }

      openSet.removeAt(currentIndex);
      openSetMap.remove(Point(currentNode.x, currentNode.y));
      closedSet.add(Point(currentNode.x, currentNode.y));

      // ถึงเป้าหมายแล้ว
      if (currentNode.x == targetNode.x && currentNode.y == targetNode.y) {
        return _retracePath(startNode, currentNode);
      }

      // ตรวจสอบช่องรอบข้าง 8 ทิศทาง (ขวา, ซ้าย, บน, ล่าง, ทแยงมุม)
      for (var neighborPos in _getNeighbors(currentNode, gridWidth, gridHeight)) {
        if (closedSet.contains(neighborPos)) {
          continue; // อยู่ใน closedSet แล้ว
        }

        if (!isWalkable(neighborPos.x, neighborPos.y)) {
          continue; // เดินไม่ได้
        }

        double moveCost = (currentNode.x != neighborPos.x && currentNode.y != neighborPos.y) ? 1.414 : 1.0;
        double newMovementCostToNeighbor = currentNode.gCost + moveCost;

        var neighborNode = openSetMap[neighborPos];

        if (neighborNode == null || newMovementCostToNeighbor < neighborNode.gCost) {
          if (neighborNode == null) {
            neighborNode = AStarNode(neighborPos.x, neighborPos.y);
            openSet.add(neighborNode);
            openSetMap[neighborPos] = neighborNode;
          }

          neighborNode.gCost = newMovementCostToNeighbor;
          neighborNode.hCost = _getDistance(neighborNode, targetNode);
          neighborNode.parent = currentNode;
        }
      }
    }

    // ถ้าไม่เจอทาง
    return [];
  }

  static List<Point<int>> _retracePath(AStarNode startNode, AStarNode endNode) {
    final path = <Point<int>>[];
    AStarNode? currentNode = endNode;

    while (currentNode != null && currentNode != startNode) {
      path.add(Point(currentNode.x, currentNode.y));
      currentNode = currentNode.parent;
    }
    
    // ไม่เอาตำแหน่งตั้งต้นไปด้วย แต่ถ้าอยากได้ก็ลบเงื่อนไข && currentNode != startNode ออก
    return path.reversed.toList();
  }

  static double _getDistance(AStarNode nodeA, AStarNode nodeB) {
    int dstX = (nodeA.x - nodeB.x).abs();
    int dstY = (nodeA.y - nodeB.y).abs();
    
    if (dstX > dstY) return 1.414 * dstY + 1.0 * (dstX - dstY);
    return 1.414 * dstX + 1.0 * (dstY - dstX);
  }

  static List<Point<int>> _getNeighbors(AStarNode node, int width, int height) {
    final neighbors = <Point<int>>[];

    for (int x = -1; x <= 1; x++) {
      for (int y = -1; y <= 1; y++) {
        if (x == 0 && y == 0) continue;

        int checkX = node.x + x;
        int checkY = node.y + y;

        if (checkX >= 0 && checkX < width && checkY >= 0 && checkY < height) {
          neighbors.add(Point(checkX, checkY));
        }
      }
    }

    return neighbors;
  }
}
