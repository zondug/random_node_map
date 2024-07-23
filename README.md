# Random Node Map Generator

<img width="1136" alt="image" src="https://github.com/user-attachments/assets/5adcd9a7-e879-4e48-a079-07c57bf2da86">


## Godot AStar2D Map Generation and Path Finding

This Godot project demonstrates the generation of a 2D map using AStar2D pathfinding algorithm. It creates a map with randomly placed nodes and connects them using Delaunay triangulation. The project also allows for finding paths between nodes on the generated map.

## Features

- Generates a 2D map with a specified number of nodes and paths
- Uses AStar2D pathfinding algorithm for efficient path finding
- Supports user interaction to select a node and find the path from the starting node to the selected node
- Visualizes the generated map, connections between nodes, and the found path
- Provides a button to regenerate the map with new random values

## Customization

You can customize the map generation by modifying the exported variables in the script:

- `plane_len`: The size of the map.
- `node_count`: The number of nodes to generate.
- `path_count`: The number of paths to generate.
- `map_scale`: The scale of the map.
- `point_distance`: The minimum distance between each node.
- `node_radius`: The radius of each node.

## License

This project is licensed under the MIT License.

## Acknowledgements

- This project utilizes the AStar2D pathfinding algorithm provided by Godot Engine.
- The map generation algorithm is based on Delaunay triangulation.

## Contributing

Contributions are welcome! If you find any issues or have suggestions for improvements, please open an issue or submit a pull request.

# Credit
This project is inspired by below:
  * https://github.com/yurkth/stsmapgen
  * https://github.com/VladoCC/Map-Generator-Godot-Tutorial?tab=readme-ov-file
