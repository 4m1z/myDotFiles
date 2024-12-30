-- sort algos
vim.api.nvim_set_keymap('n', '<leader>qs', [[:lua InsertQuickSortSnippet()<CR>]], { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<leader>ms', [[:lua InsertMergeSortSnippet()<CR>]], { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<leader>hs', [[:lua InsertHeapSortSnippet()<CR>]], { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<leader>cs', [[:lua InsertCountingSortSnippet()<CR>]], { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<leader>rs', [[:lua InsertRadixSortSnippet()<CR>]], { noremap = true, silent = true })
-- search algos
vim.api.nvim_set_keymap('n', '<leader>bs', [[:lua InsertBinarySearchSnippet()<CR>]], { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<leader>dfs', [[:lua InsertDFSSnippet()<CR>]], { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<leader>bfs', [[:lua ImportBFSSnippet()<CR>]], { noremap = true, silent = true })
-- dfs algo for matrix
vim.api.nvim_set_keymap('n', '<leader>dfsm', [[:lua ImportDFSSnippet()<CR>]], { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<leader>bfsm', [[:lua ImportBFSMatrixSnippet()<CR>]], { noremap = true, silent = true })
-- graph
vim.api.nvim_set_keymap('n', '<leader>gdi', [[:lua ImportDijkstra()<CR>]], { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<leader>gbel', [[:lua ImportBellmanFord()<CR>]], { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<leader>gflw', [[:lua ImportFloydWarshall()<CR>]], { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<leader>gka', [[:lua ImportKruskalAlgorithm()<CR>]], { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<leader>gpa', [[:lua ImportPrimesAlgorithm()<CR>]], { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<leader>gto', [[:lua ImportTopologicalSortAlgorithm()<CR>]],
    { noremap = true, silent = true })
--- SCCs
vim.api.nvim_set_keymap('n', '<leader>gta', [[:lua ImportTarjanAlgorithm()<CR>]], { noremap = true, silent = true })

-- Dynamic programming
vim.api.nvim_set_keymap('n', '<leader>dks', [[:lua ImportKnapsackAlgorithm()<CR>]], { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<leader>dlcs', [[:lua ImportLCS()<CR>]], { noremap = true, silent = true })

vim.api.nvim_set_keymap('n', '<leader>dles', [[:lua ImportLIS()<CR>]], { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<leader>dmc', [[:lua ImportMinimomCoinChange()<CR>]], { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<leader>dmm', [[:lua ImportMatrixChainMultiplication()<CR>]],
    { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<leader>ded', [[:lua ImportMatrixChainMultiplication()<CR>]],
    { noremap = true, silent = true })

-- data structures
vim.api.nvim_set_keymap('n', '<leader>qu', [[:lua ImportQueue()<CR>]],
    { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<leader>st', [[:lua ImportStack()<CR>]],
    { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<leader>lli', [[:lua ImportLinkedList()<CR>]],
    { noremap = true, silent = true })

vim.api.nvim_set_keymap('n', '<leader>pq', [[:lua ImportPQ()<CR>]],
    { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<leader>dsu', [[:lua ImportDSU()<CR>]],
    { noremap = true, silent = true })



-- quick sort
function InsertQuickSortSnippet()
    local current_line = vim.fn.line('.')
    local indent = vim.fn.indent(current_line)

    local snippet = "func quickSort(arr []int) {"
    vim.fn.append(current_line, snippet)

    current_line = current_line + 1
    vim.fn.append(current_line, string.rep(' ', indent + 4) .. "if len(arr) <= 1 {")
    current_line = current_line + 1
    vim.fn.append(current_line, string.rep(' ', indent + 8) .. "return")
    current_line = current_line + 1
    vim.fn.append(current_line, string.rep(' ', indent + 4) .. "}")

    current_line = current_line + 1
    vim.fn.append(current_line, string.rep(' ', indent + 4) .. "pivot := arr[len(arr)/2]")
    current_line = current_line + 1
    vim.fn.append(current_line, string.rep(' ', indent + 4) .. "var less, equal, greater []int")
    current_line = current_line + 1
    vim.fn.append(current_line, string.rep(' ', indent + 4) .. "for _, value := range arr {")
    current_line = current_line + 1
    vim.fn.append(current_line, string.rep(' ', indent + 8) .. "switch {")
    current_line = current_line + 1
    vim.fn.append(current_line, string.rep(' ', indent + 12) .. "case value < pivot:")
    current_line = current_line + 1
    vim.fn.append(current_line, string.rep(' ', indent + 16) .. "less = append(less, value)")
    current_line = current_line + 1
    vim.fn.append(current_line, string.rep(' ', indent + 12) .. "case value == pivot:")
    current_line = current_line + 1
    vim.fn.append(current_line, string.rep(' ', indent + 16) .. "equal = append(equal, value)")
    current_line = current_line + 1
    vim.fn.append(current_line, string.rep(' ', indent + 12) .. "case value > pivot:")
    current_line = current_line + 1
    vim.fn.append(current_line, string.rep(' ', indent + 16) .. "greater = append(greater, value)")
    current_line = current_line + 1
    vim.fn.append(current_line, string.rep(' ', indent + 8) .. "}")
    current_line = current_line + 1
    vim.fn.append(current_line, string.rep(' ', indent + 4) .. "}")
    current_line = current_line + 1
    vim.fn.append(current_line, string.rep(' ', indent + 4) .. "quickSort(less)")
    current_line = current_line + 1
    vim.fn.append(current_line, string.rep(' ', indent + 4) .. "quickSort(greater)")
    current_line = current_line + 1
    vim.fn.append(current_line, string.rep(' ', indent + 4) .. "copy(arr, append(append(less, equal...), greater...))")
    current_line = current_line + 1

    vim.fn.append(current_line, string.rep(' ', indent) .. "}")

    current_line = current_line + 1
    vim.fn.append(current_line, "")
end

-- merge sort
--
function InsertMergeSortSnippet()
    local mergeSortTemplate = [[

func mergeSort(arr []int) []int {
	if len(arr) <= 1 {
		return arr
	}

	m := len(arr) / 2

	l := mergeSort(arr[:m])
	r := mergeSort(arr[m:])

	return merge(l, r)
}

func merge(l, r []int) []int {
	res := make([]int, 0, len(l)+len(r))
	li, ri := 0, 0

	for li < len(l) || ri < len(r) {
		if li < len(l) && ri < len(r) {
			if l[li] > r[ri] {
				res = append(res, r[ri])
				ri++
			} else {
				res = append(res, l[li])
				li++
			}
		} else if li < len(l) {
			res = append(res, l[li])
			li++
		} else {
			res = append(res, r[ri])
			ri++
		}
	}

	return res
}
]]

    local cursor = vim.fn.getcurpos()
    local line = cursor[2]

    for i, snippetLine in ipairs(vim.fn.split(mergeSortTemplate, '\n')) do
        vim.fn.append(line - 1 + i, snippetLine)
    end
end

function InsertHeapSortSnippet()
    local current_line = vim.fn.line('.')
    local indent = vim.fn.indent(current_line)

    local snippet = "func heapSort(arr []int) {\n"
    snippet = snippet .. string.rep(' ', indent + 4) .. "n := len(arr)\n"
    snippet = snippet .. string.rep(' ', indent + 4) .. "for i := n/2 - 1; i >= 0; i-- {\n"
    snippet = snippet .. string.rep(' ', indent + 8) .. "heapify(arr, n, i)\n"
    snippet = snippet .. string.rep(' ', indent + 4) .. "}\n"
    snippet = snippet .. string.rep(' ', indent + 4) .. "for i := n - 1; i > 0; i-- {\n"
    snippet = snippet .. string.rep(' ', indent + 8) .. "arr[0], arr[i] = arr[i], arr[0]\n"
    snippet = snippet .. string.rep(' ', indent + 8) .. "heapify(arr, i, 0)\n"
    snippet = snippet .. string.rep(' ', indent + 4) .. "}\n"
    snippet = snippet .. "}\n\n"
    snippet = snippet .. "func heapify(arr []int, n, i int) {\n"
    snippet = snippet .. string.rep(' ', indent + 4) .. "largest := i\n"
    snippet = snippet .. string.rep(' ', indent + 4) .. "left := 2*i + 1\n"
    snippet = snippet .. string.rep(' ', indent + 4) .. "right := 2*i + 2\n"
    snippet = snippet .. string.rep(' ', indent + 4) .. "if left < n && arr[left] > arr[largest] {\n"
    snippet = snippet .. string.rep(' ', indent + 8) .. "largest = left\n"
    snippet = snippet .. string.rep(' ', indent + 4) .. "}\n"
    snippet = snippet .. string.rep(' ', indent + 4) .. "if right < n && arr[right] > arr[largest] {\n"
    snippet = snippet .. string.rep(' ', indent + 8) .. "largest = right\n"
    snippet = snippet .. string.rep(' ', indent + 4) .. "}\n"
    snippet = snippet .. string.rep(' ', indent + 4) .. "if largest != i {\n"
    snippet = snippet .. string.rep(' ', indent + 8) .. "arr[i], arr[largest] = arr[largest], arr[i]\n"
    snippet = snippet .. string.rep(' ', indent + 8) .. "heapify(arr, n, largest)\n"
    snippet = snippet .. string.rep(' ', indent + 4) .. "}\n"
    snippet = snippet .. "}\n"

    local lines = vim.fn.split(snippet, '\n')
    vim.fn.append(current_line, lines)
end

function InsertCountingSortSnippet()
    local current_line = vim.fn.line('.')
    local indent = vim.fn.indent(current_line)

    local snippet = "func countingSort(arr []int) []int {\n"
    snippet = snippet .. string.rep(' ', indent + 4) .. "max := maxElement(arr)\n"
    snippet = snippet .. string.rep(' ', indent + 4) .. "min := minElement(arr)\n"
    snippet = snippet .. string.rep(' ', indent + 4) .. "rangeSize := max - min + 1\n"
    snippet = snippet .. string.rep(' ', indent + 4) .. "count := make([]int, rangeSize)\n"
    snippet = snippet .. string.rep(' ', indent + 4) .. "output := make([]int, len(arr))\n"
    snippet = snippet .. string.rep(' ', indent + 4) .. "for i := 0; i < len(arr); i++ {\n"
    snippet = snippet .. string.rep(' ', indent + 8) .. "count[arr[i]-min]++\n"
    snippet = snippet .. string.rep(' ', indent + 4) .. "}\n"
    snippet = snippet .. string.rep(' ', indent + 4) .. "for i := 1; i < rangeSize; i++ {\n"
    snippet = snippet .. string.rep(' ', indent + 8) .. "count[i] += count[i-1]\n"
    snippet = snippet .. string.rep(' ', indent + 4) .. "}\n"
    snippet = snippet .. string.rep(' ', indent + 4) .. "for i := len(arr) - 1; i >= 0; i-- {\n"
    snippet = snippet .. string.rep(' ', indent + 8) .. "output[count[arr[i]-min]-1] = arr[i]\n"
    snippet = snippet .. string.rep(' ', indent + 8) .. "count[arr[i]-min]--\n"
    snippet = snippet .. string.rep(' ', indent + 4) .. "}\n"
    snippet = snippet .. string.rep(' ', indent + 4) .. "return output\n"
    snippet = snippet .. "}\n\n"
    snippet = snippet .. "func maxElement(arr []int) int {\n"
    snippet = snippet .. string.rep(' ', indent + 4) .. "max := arr[0]\n"
    snippet = snippet .. string.rep(' ', indent + 4) .. "for _, val := range arr {\n"
    snippet = snippet .. string.rep(' ', indent + 8) .. "if val > max {\n"
    snippet = snippet .. string.rep(' ', indent + 12) .. "max = val\n"
    snippet = snippet .. string.rep(' ', indent + 8) .. "}\n"
    snippet = snippet .. string.rep(' ', indent + 4) .. "}\n"
    snippet = snippet .. string.rep(' ', indent + 4) .. "return max\n"
    snippet = snippet .. "}\n\n"
    snippet = snippet .. "func minElement(arr []int) int {\n"
    snippet = snippet .. string.rep(' ', indent + 4) .. "min := arr[0]\n"
    snippet = snippet .. string.rep(' ', indent + 4) .. "for _, val := range arr {\n"
    snippet = snippet .. string.rep(' ', indent + 8) .. "if val < min {\n"
    snippet = snippet .. string.rep(' ', indent + 12) .. "min = val\n"
    snippet = snippet .. string.rep(' ', indent + 8) .. "}\n"
    snippet = snippet .. string.rep(' ', indent + 4) .. "}\n"
    snippet = snippet .. string.rep(' ', indent + 4) .. "return min\n"
    snippet = snippet .. "}\n"

    local lines = vim.fn.split(snippet, '\n')
    vim.fn.append(current_line, lines)
end

function InsertRadixSortSnippet()
    local current_line = vim.fn.line('.')
    local indent = vim.fn.indent(current_line)

    local snippet = "func radixSort(arr []int) {\n"
    snippet = snippet .. string.rep(' ', indent + 4) .. "max := maxElement(arr)\n"
    snippet = snippet .. string.rep(' ', indent + 4) .. "exp := 1\n"
    snippet = snippet .. string.rep(' ', indent + 4) .. "n := len(arr)\n"
    snippet = snippet .. string.rep(' ', indent + 4) .. "output := make([]int, n)\n"
    snippet = snippet .. string.rep(' ', indent + 4) .. "for exp <= max {\n"
    snippet = snippet .. string.rep(' ', indent + 8) .. "count := make([]int, 10)\n"
    snippet = snippet .. string.rep(' ', indent + 8) .. "for i := 0; i < n; i++ {\n"
    snippet = snippet .. string.rep(' ', indent + 12) .. "count[(arr[i]/exp)%10]++\n"
    snippet = snippet .. string.rep(' ', indent + 8) .. "}\n"
    snippet = snippet .. string.rep(' ', indent + 8) .. "for i := 1; i < 10; i++ {\n"
    snippet = snippet .. string.rep(' ', indent + 12) .. "count[i] += count[i-1]\n"
    snippet = snippet .. string.rep(' ', indent + 8) .. "}\n"
    snippet = snippet .. string.rep(' ', indent + 8) .. "for i := n - 1; i >= 0; i-- {\n"
    snippet = snippet .. string.rep(' ', indent + 12) .. "output[count[(arr[i]/exp)%10]-1] = arr[i]\n"
    snippet = snippet .. string.rep(' ', indent + 12) .. "count[(arr[i]/exp)%10]--\n"
    snippet = snippet .. string.rep(' ', indent + 8) .. "}\n"
    snippet = snippet .. string.rep(' ', indent + 8) .. "for i := 0; i < n; i++ {\n"
    snippet = snippet .. string.rep(' ', indent + 12) .. "arr[i] = output[i]\n"
    snippet = snippet .. string.rep(' ', indent + 8) .. "}\n"
    snippet = snippet .. string.rep(' ', indent + 8) .. "exp *= 10\n"
    snippet = snippet .. string.rep(' ', indent + 4) .. "}\n"
    snippet = snippet .. "}\n\n"
    snippet = snippet .. "func maxElement(arr []int) int {\n"
    snippet = snippet .. string.rep(' ', indent + 4) .. "max := arr[0]\n"
    snippet = snippet .. string.rep(' ', indent + 4) .. "for _, val := range arr {\n"
    snippet = snippet .. string.rep(' ', indent + 8) .. "if val > max {\n"
    snippet = snippet .. string.rep(' ', indent + 12) .. "max = val\n"
    snippet = snippet .. string.rep(' ', indent + 8) .. "}\n"
    snippet = snippet .. string.rep(' ', indent + 4) .. "}\n"
    snippet = snippet .. string.rep(' ', indent + 4) .. "return max\n"
    snippet = snippet .. "}\n"

    local lines = vim.fn.split(snippet, '\n')
    vim.fn.append(current_line, lines)
end

function InsertBinarySearchSnippet()
    local current_line = vim.fn.line('.')
    local indent = vim.fn.indent(current_line)

    local snippet = "func binarySearch(arr []int, target int) int {\n"
    snippet = snippet .. string.rep(' ', indent + 4) .. "left := 0\n"
    snippet = snippet .. string.rep(' ', indent + 4) .. "right := len(arr) - 1\n"
    snippet = snippet .. string.rep(' ', indent + 4) .. "for left <= right {\n"
    snippet = snippet .. string.rep(' ', indent + 8) .. "mid := left + (right-left)/2\n"
    snippet = snippet .. string.rep(' ', indent + 8) .. "if arr[mid] == target {\n"
    snippet = snippet .. string.rep(' ', indent + 12) .. "return mid\n"
    snippet = snippet .. string.rep(' ', indent + 8) .. "} else if arr[mid] < target {\n"
    snippet = snippet .. string.rep(' ', indent + 12) .. "left = mid + 1\n"
    snippet = snippet .. string.rep(' ', indent + 8) .. "} else {\n"
    snippet = snippet .. string.rep(' ', indent + 12) .. "right = mid - 1\n"
    snippet = snippet .. string.rep(' ', indent + 8) .. "}\n"
    snippet = snippet .. string.rep(' ', indent + 4) .. "}\n"
    snippet = snippet .. string.rep(' ', indent + 4) .. "return -1 // Element not found\n"
    snippet = snippet .. "}\n"

    local lines = vim.fn.split(snippet, '\n')
    vim.fn.append(current_line, lines)
end

function InsertDFSSnippet()
    local current_line = vim.fn.line('.')
    local indent = vim.fn.indent(current_line)

    local snippet = "type Graph struct {\n"
    snippet = snippet .. string.rep(' ', indent + 4) .. "adj map[int][]int\n"
    snippet = snippet .. "}\n\n"
    snippet = snippet .. "func DFS(g *Graph, v int, visited map[int]bool) {\n"
    snippet = snippet .. string.rep(' ', indent + 4) .. "visited[v] = true\n"
    snippet = snippet .. string.rep(' ', indent + 4) .. "fmt.Printf(\"Visiting node %d\\n\", v)\n"
    snippet = snippet .. string.rep(' ', indent + 4) .. "for _, neighbor := range g.adj[v] {\n"
    snippet = snippet .. string.rep(' ', indent + 8) .. "if !visited[neighbor] {\n"
    snippet = snippet .. string.rep(' ', indent + 12) .. "DFS(g, neighbor, visited)\n"
    snippet = snippet .. string.rep(' ', indent + 8) .. "}\n"
    snippet = snippet .. string.rep(' ', indent + 4) .. "}\n"
    snippet = snippet .. "}\n\n"

    local lines = vim.fn.split(snippet, '\n')
    vim.fn.append(current_line, lines)
end

function ImportDFSSnippet()
    -- Define your DFS snippet template here
    local dfsTemplate = [[
var Directions = [][]int{
    {-1, 0},
    {1, 0},
    {0, -1},
    {0, 1},
}

func DFS(matrix [][]int, visited [][]bool, x, y int) {
    visited[x][y] = true
    fmt.Printf("Visiting node at (%d, %d)\n", x, y)

    for _, dir := range Directions {
        newX, newY := x+dir[0], y+dir[1]

        if newX >= 0 && newX < len(matrix) && newY >= 0 && newY < len(matrix[0]) && !visited[newX][newY] && matrix[newX][newY] == 1 {
            DFS(matrix, visited, newX, newY)
        }
    }
}

func dfsMatrix(matrix [][]int) {
    Rows, Cols := len(matrix), len(matrix[0])

    visited := make([][]bool, Rows)
    for i := range visited {
        visited[i] = make([]bool, Cols)
    }

    DFS(matrix, visited, 0, 0)
}
]]

    -- Get current line and column
    local cursor = vim.fn.getcurpos()
    local line = cursor[2]

    -- Split the snippet into lines and insert each line at the current position
    for i, snippetLine in ipairs(vim.fn.split(dfsTemplate, '\n')) do
        vim.fn.append(line - 1 + i, snippetLine)
    end
end

-- bfs graph
function ImportBFSSnippet()
    local Template = [[
type Graph struct {
    vertices int
    adjacencyList map[int][]int
}

func (g *Graph) AddEdge(v1, v2 int) {
    g.adjacencyList[v1] = append(g.adjacencyList[v1], v2)
}


func (g *Graph) BFS(startVertex int) {
    visited := make(map[int]bool)
    queue := list.New()

    visited[startVertex] = true
    queue.PushBack(startVertex)

    for queue.Len() > 0 {
        currentVertex := queue.Front().Value.(int)
        fmt.Printf("Visited vertex: %d\n", currentVertex)
        queue.Remove(queue.Front())

        for _, neighbor := range g.adjacencyList[currentVertex] {
            if !visited[neighbor] {
                visited[neighbor] = true
                queue.PushBack(neighbor)
            }
        }
    }
}
]]

    -- Get current line and column
    local cursor = vim.fn.getcurpos()
    local line = cursor[2]

    -- Split the snippet into lines and insert each line at the current position
    for i, snippetLine in ipairs(vim.fn.split(Template, '\n')) do
        vim.fn.append(line - 1 + i, snippetLine)
    end
end

-- bfs matrix
function ImportBFSMatrixSnippet()
    local Template = [[
    import (
    "fmt"
    "container/list"
)

var Directions = [][]int{
    {-1, 0}, // Up
    {1, 0},  // Down
    {0, -1}, // Left
    {0, 1},  // Right
}

type Node struct {
    x, y int
}

func BFS(matrix [][]int, startX, startY int) {
    numRows := len(matrix)
    if numRows == 0 {
        return
    }
    numCols := len(matrix[0])

    visited := make([][]bool, numRows)
    for i := range visited {
        visited[i] = make([]bool, numCols)
    }

    queue := list.New()
    startNode := Node{x: startX, y: startY}
    queue.PushBack(startNode)
    visited[startX][startY] = true

    for queue.Len() > 0 {
        currentNode := queue.Front().Value.(Node)
        queue.Remove(queue.Front())

        fmt.Printf("Visited node at (%d, %d)\n", currentNode.x, currentNode.y)

        for _, dir := range Directions {
            newX, newY := currentNode.x+dir[0], currentNode.y+dir[1]

            if newX >= 0 && newX < numRows && newY >= 0 && newY < numCols && !visited[newX][newY] && matrix[newX][newY] == 1 {
                newNode := Node{x: newX, y: newY}
                queue.PushBack(newNode)
                visited[newX][newY] = true
            }
        }
    }
}

func BFSMatrix(matrix [][]int, startX, startY int) {
    fmt.Printf("Starting BFS from (%d, %d):\n", startX, startY)
    BFS(matrix, startX, startY)
}

]]

    -- Get current line and column
    local cursor = vim.fn.getcurpos()
    local line = cursor[2]

    -- Split the snippet into lines and insert each line at the current position
    for i, snippetLine in ipairs(vim.fn.split(Template, '\n')) do
        vim.fn.append(line - 1 + i, snippetLine)
    end
end

-- dijkstra
function ImportDijkstra()
    local Template = [[

import (
	"fmt"
	"math"
)

type Graph struct {
	vertices int
	edges    map[int]map[int]int
}

func NewGraph(vertices int) *Graph {
	return &Graph{
		vertices: vertices,
		edges:    make(map[int]map[int]int),
	}
}

func (g *Graph) AddEdge(source, destination, weight int) {
	if g.edges[source] == nil {
		g.edges[source] = make(map[int]int)
	}
	g.edges[source][destination] = weight
}

func Dijkstra(graph *Graph, startVertex int) map[int]int {
	distances := make(map[int]int)
	for vertex := 0; vertex < graph.vertices; vertex++ {
		distances[vertex] = math.MaxInt32
	}
	distances[startVertex] = 0

	visited := make(map[int]bool)

	for i := 0; i < graph.vertices-1; i++ {
		minVertex := findMinVertex(distances, visited)
		visited[minVertex] = true

		for vertex, weight := range graph.edges[minVertex] {
			if !visited[vertex] {
				newDistance := distances[minVertex] + weight
				if newDistance < distances[vertex] {
					distances[vertex] = newDistance
				}
			}
		}
	}

	return distances
}

func findMinVertex(distances map[int]int, visited map[int]bool) int {
	minVertex := -1
	minDistance := math.MaxInt32

	for vertex, distance := range distances {
		if !visited[vertex] && distance < minDistance {
			minVertex = vertex
			minDistance = distance
		}
	}

	return minVertex
}

]]

    local cursor = vim.fn.getcurpos()
    local line = cursor[2]

    for i, snippetLine in ipairs(vim.fn.split(Template, '\n')) do
        vim.fn.append(line - 1 + i, snippetLine)
    end
end

function ImportBellmanFord()
    local Template =
    [[
import (
	"fmt"
	"math"
)

type Edge struct {
	source, destination, weight int
}

type Graph struct {
	vertices, edges int
	edgeList       []Edge
}

func NewGraph(vertices, edges int) *Graph {
	return &Graph{
		vertices: vertices,
		edges:    edges,
		edgeList: make([]Edge, 0),
	}
}

func (g *Graph) AddEdge(source, destination, weight int) {
	g.edgeList = append(g.edgeList, Edge{source, destination, weight})
}

func BellmanFord(graph *Graph, startVertex int) ([]int, []int) {
	distances := make([]int, graph.vertices)
	parents := make([]int, graph.vertices)

	for i := range distances {
		distances[i] = math.MaxInt32
		parents[i] = -1
	}

	distances[startVertex] = 0

	for i := 1; i <= graph.vertices-1; i++ {
		for _, edge := range graph.edgeList {
			u, v, weight := edge.source, edge.destination, edge.weight
			if distances[u] != math.MaxInt32 && distances[u]+weight < distances[v] {
				distances[v] = distances[u] + weight
				parents[v] = u
			}
		}
	}

	// Check for negative weight cycles
	for _, edge := range graph.edgeList {
		u, v, weight := edge.source, edge.destination, edge.weight
		if distances[u] != math.MaxInt32 && distances[u]+weight < distances[v] {
			fmt.Println("Graph contains negative weight cycle")
		}
	}

	return distances, parents
}
]]

    local cursor = vim.fn.getcurpos()
    local line = cursor[2]

    for i, snippetLine in ipairs(vim.fn.split(Template, '\n')) do
        vim.fn.append(line - 1 + i, snippetLine)
    end
end

--Shortest distances between all pairs of vertices:
function ImportFloydWarshall()
    local Template =
    [[
import (
	"fmt"
	"math"
)

type Graph struct {
	vertices int
	matrix   [][]int
}

func NewGraph(vertices int) *Graph {
	matrix := make([][]int, vertices)
	for i := range matrix {
		matrix[i] = make([]int, vertices)
		for j := range matrix[i] {
			if i == j {
				matrix[i][j] = 0
			} else {
				matrix[i][j] = math.MaxInt32
			}
		}
	}
	return &Graph{
		vertices: vertices,
		matrix:   matrix,
	}
}

func (g *Graph) AddEdge(source, destination, weight int) {
	g.matrix[source][destination] = weight
}

func FloydWarshall(graph *Graph) [][]int {
	distances := make([][]int, graph.vertices)
	for i := range distances {
		distances[i] = make([]int, graph.vertices)
		copy(distances[i], graph.matrix[i])
	}

	for k := 0; k < graph.vertices; k++ {
		for i := 0; i < graph.vertices; i++ {
			for j := 0; j < graph.vertices; j++ {
				if distances[i][k]+distances[k][j] < distances[i][j] {
					distances[i][j] = distances[i][k] + distances[k][j]
				}
			}
		}
	}

	return distances
}

func main() {
	vertices := 4
	graph := NewGraph(vertices)

	graph.AddEdge(0, 1, 3)
	graph.AddEdge(0, 2, 6)
	graph.AddEdge(1, 2, 2)
	graph.AddEdge(1, 3, 1)
	graph.AddEdge(2, 1, 1)
	graph.AddEdge(2, 3, 4)
	graph.AddEdge(3, 0, 2)
	graph.AddEdge(3, 2, 5)

	distances := FloydWarshall(graph)

	fmt.Println("Shortest distances between all pairs of vertices:")
	for i := 0; i < vertices; i++ {
		for j := 0; j < vertices; j++ {
			fmt.Printf("From vertex %d to vertex %d: Distance %d\n", i, j, distances[i][j])
		}
	}
}

]]

    local cursor = vim.fn.getcurpos()
    local line = cursor[2]

    for i, snippetLine in ipairs(vim.fn.split(Template, '\n')) do
        vim.fn.append(line - 1 + i, snippetLine)
    end
end

function ImportKruskalAlgorithm()
    local Template =
    [[

package main

import (
	"fmt"
	"sort"
)

// Edge represents an edge in the graph.
type Edge struct {
	u, v, weight int
}

// Kruskal's algorithm to find the Minimum Spanning Tree.
func kruskal(graph []Edge, numVertices int) []Edge {
	// Sort the edges in ascending order of weight.
	sort.Slice(graph, func(i, j int) bool {
		return graph[i].weight < graph[j].weight
	})

	// Create a parent array to keep track of connected components.
	parent := make([]int, numVertices)
	for i := range parent {
		parent[i] = i
	}

	// Initialize variables to track MST edges and total weight.
	var mst []Edge
	var mstWeight int

	// Function to find the root of a tree.
	findRoot := func(vertex int) int {
		for vertex != parent[vertex] {
			vertex = parent[vertex]
		}
		return vertex
	}

	// Iterate through the sorted edges and add them to the MST if they don't create a cycle.
	for _, edge := range graph {
		rootU := findRoot(edge.u)
		rootV := findRoot(edge.v)

		// If adding this edge doesn't create a cycle, include it in the MST.
		if rootU != rootV {
			mst = append(mst, edge)
			mstWeight += edge.weight

			// Merge the two components.
			parent[rootU] = rootV
		}
	}

	return mst
}

func main() {
	// Example graph represented as a slice of edges (u, v, weight).
	graph := []Edge{
		{0, 1, 4},
		{0, 7, 8},
		{1, 2, 8},
		{1, 7, 11},
		{2, 3, 7},
		{2, 5, 4},
		{2, 8, 2},
		{3, 4, 9},
		{3, 5, 14},
		{4, 5, 10},
		{5, 6, 2},
		{6, 7, 1},
		{6, 8, 6},
		{7, 8, 7},
	}

	numVertices := 9

	// Find the Minimum Spanning Tree using Kruskal's algorithm.
	mst := kruskal(graph, numVertices)

	// Print the MST edges and total weight.
	fmt.Println("Minimum Spanning Tree edges:")
	for _, edge := range mst {
		fmt.Printf("(%d, %d) Weight: %d\n", edge.u, edge.v, edge.weight)
	}
}

]]
    local cursor = vim.fn.getcurpos()
    local line = cursor[2]

    for i, snippetLine in ipairs(vim.fn.split(Template, '\n')) do
        vim.fn.append(line - 1 + i, snippetLine)
    end
end

function ImportPrimesAlgorithm()
    local Template = [[
package main

import (
	"container/heap"
	"fmt"
)

// Edge represents an edge in the graph.
type Edge struct {
	vertex int
	weight int
}

// Graph represents a graph using an adjacency list.
type Graph map[int][]Edge

// Item represents an item in the priority queue.
type Item struct {
	vertex int
	weight int
	index  int
}

// PriorityQueue is a min-heap based priority queue.
type PriorityQueue []*Item

func (pq PriorityQueue) Len() int { return len(pq) }

func (pq PriorityQueue) Less(i, j int) bool {
	return pq[i].weight < pq[j].weight
}

func (pq PriorityQueue) Swap(i, j int) {
	pq[i], pq[j] = pq[j], pq[i]
	pq[i].index = i
	pq[j].index = j
}

func (pq *PriorityQueue) Push(x interface{}) {
	n := len(*pq)
	item := x.(*Item)
	item.index = n
	*pq = append(*pq, item)
}

func (pq *PriorityQueue) Pop() interface{} {
	old := *pq
	n := len(old)
	item := old[n-1]
	item.index = -1 // for safety
	*pq = old[0 : n-1]
	return item
}

// Prim's algorithm to find the Minimum Spanning Tree.
func prim(graph Graph) []Edge {
	visited := make(map[int]bool)
	pq := make(PriorityQueue, 0)

	// Start from an arbitrary vertex (e.g., vertex 0).
	startVertex := 0
	visited[startVertex] = true

	// Initialize the priority queue with edges from the starting vertex.
	for _, edge := range graph[startVertex] {
		heap.Push(&pq, &Item{edge.vertex, edge.weight, 0})
	}

	var mst []Edge

	for len(pq) > 0 {
		// Extract the edge with the minimum weight from the priority queue.
		item := heap.Pop(&pq).(*Item)
		v := item.vertex
		w := item.weight

		// If the destination vertex is already visited, skip it.
		if visited[v] {
			continue
		}

		// Mark the destination vertex as visited and add the edge to the MST.
		visited[v] = true
		mst = append(mst, Edge{v, w})

		// Add adjacent edges to the priority queue.
		for _, edge := range graph[v] {
			if !visited[edge.vertex] {
				heap.Push(&pq, &Item{edge.vertex, edge.weight, 0})
			}
		}
	}

	return mst
}

func main() {
	// Example graph represented as an adjacency list.
	graph := make(Graph)
	graph[0] = []Edge{{1, 2}, {2, 4}}
	graph[1] = []Edge{{0, 2}, {2, 1}, {3, 3}}
	graph[2] = []Edge{{0, 4}, {1, 1}, {3, 5}}
	graph[3] = []Edge{{1, 3}, {2, 5}}

	// Find the Minimum Spanning Tree using Prim's algorithm.
	mst := prim(graph)

	// Print the MST edges.
	fmt.Println("Minimum Spanning Tree edges:")
	for _, edge := range mst {
		fmt.Printf("(%d, %d) Weight: %d\n", 0, edge.vertex, edge.weight)
	}
}
]]

    local cursor = vim.fn.getcurpos()
    local line = cursor[2]

    for i, snippetLine in ipairs(vim.fn.split(Template, '\n')) do
        vim.fn.append(line - 1 + i, snippetLine)
    end
end

function ImportTopologicalSortAlgorithm()
    local Template = [[

package main

import (
    "fmt"
)

type Graph struct {
    vertices int
    adjacencyList map[int][]int
}

func NewGraph(vertices int) *Graph {
    return &Graph{
        vertices: vertices,
        adjacencyList: make(map[int][]int),
    }
}

func (g *Graph) AddEdge(u, v int) {
    g.adjacencyList[u] = append(g.adjacencyList[u], v)
}

func (g *Graph) topologicalSortUtil(v int, visited map[int]bool, stack *[]int) {
    visited[v] = true

    for _, neighbor := range g.adjacencyList[v] {
        if !visited[neighbor] {
            g.topologicalSortUtil(neighbor, visited, stack)
        }
    }

    *stack = append(*stack, v)
}

func (g *Graph) TopologicalSort() []int {
    visited := make(map[int]bool)
    stack := []int{}

    for i := 0; i < g.vertices; i++ {
        if !visited[i] {
            g.topologicalSortUtil(i, visited, &stack)
        }
    }

    // Reverse the stack to get the topological order
    result := make([]int, 0, len(stack))
    for i := len(stack) - 1; i >= 0; i-- {
        result = append(result, stack[i])
    }

    return result
}

func main() {
    g := NewGraph(6)
    g.AddEdge(5, 2)
    g.AddEdge(5, 0)
    g.AddEdge(4, 0)
    g.AddEdge(4, 1)
    g.AddEdge(2, 3)
    g.AddEdge(3, 1)

    sortedOrder := g.TopologicalSort()

    fmt.Println("Topological Sort:")
    for _, vertex := range sortedOrder {
        fmt.Printf("%d ", vertex)
    }
    fmt.Println()
}


]]

    local cursor = vim.fn.getcurpos()
    local line = cursor[2]

    for i, snippetLine in ipairs(vim.fn.split(Template, '\n')) do
        vim.fn.append(line - 1 + i, snippetLine)
    end
end

function ImportTarjanAlgorithm()
    local Template = [[

package main

import (
    "fmt"
)

type Graph struct {
    vertices int
    adjacencyList map[int][]int
    time        int
    ids         []int
    low         []int
    onStack     []bool
    stack       []int
    sccs        [][]int
}

func NewGraph(vertices int) *Graph {
    return &Graph{
        vertices:     vertices,
        adjacencyList: make(map[int][]int),
        time:        0,
        ids:         make([]int, vertices),
        low:         make([]int, vertices),
        onStack:     make([]bool, vertices),
    }
}

func (g *Graph) AddEdge(u, v int) {
    g.adjacencyList[u] = append(g.adjacencyList[u], v)
}

func (g *Graph) tarjan(v int) {
    g.ids[v] = g.time
    g.low[v] = g.time
    g.time++
    g.stack = append(g.stack, v)
    g.onStack[v] = true

    for _, w := range g.adjacencyList[v] {
        if g.ids[w] == -1 {
            g.tarjan(w)
            if g.low[w] < g.low[v] {
                g.low[v] = g.low[w]
            }
        } else if g.onStack[w] && g.ids[w] < g.low[v] {
            g.low[v] = g.ids[w]
        }
    }

    if g.ids[v] == g.low[v] {
        scc := []int{}
        for {
            w := g.stack[len(g.stack)-1]
            g.stack = g.stack[:len(g.stack)-1]
            g.onStack[w] = false
            scc = append(scc, w)
            if w == v {
                break
            }
        }
        g.sccs = append(g.sccs, scc)
    }
}

func (g *Graph) StronglyConnectedComponents() [][]int {
    for i := 0; i < g.vertices; i++ {
        if g.ids[i] == -1 {
            g.tarjan(i)
        }
    }
    return g.sccs
}

func main() {
    g := NewGraph(8)
    g.AddEdge(0, 1)
    g.AddEdge(1, 2)
    g.AddEdge(2, 0)
    g.AddEdge(3, 4)
    g.AddEdge(4, 5)
    g.AddEdge(5, 3)
    g.AddEdge(2, 6)
    g.AddEdge(6, 7)

    sccs := g.StronglyConnectedComponents()

    fmt.Println("Strongly Connected Components:")
    for _, scc := range sccs {
        fmt.Println(scc)
    }
}
]]
    local cursor = vim.fn.getcurpos()
    local line = cursor[2]

    for i, snippetLine in ipairs(vim.fn.split(Template, '\n')) do
        vim.fn.append(line - 1 + i, snippetLine)
    end
end

function ImportKnapsackAlgorithm()
    local Template = [[
package main

import (
    "fmt"
)
// knapsackDP finds the maximum value that can be obtained given the weight capacity
// and a list of items with weights and values.
func knapsackDP(weights, values []int, capacity int) int {
    n := len(weights)

    // Create a 2D slice to store the results of subproblems
    dp := make([][]int, n+1)
    for i := range dp {
        dp[i] = make([]int, capacity+1)
    }

    // Fill the dp table using bottom-up dynamic programming
    for i := 1; i <= n; i++ {
        for w := 1; w <= capacity; w++ {
            // If the current item's weight exceeds the current capacity, skip it
            if weights[i-1] > w {
                dp[i][w] = dp[i-1][w]
            } else {
                // Otherwise, choose the maximum value between including and excluding the item
                dp[i][w] = max(dp[i-1][w], values[i-1]+dp[i-1][w-weights[i-1]]



    local Template2 = [[ )
            }
        }
    }

    // The value in the bottom-right cell represents the maximum value
    return dp[n][capacity]
}

// max returns the maximum of two integers
func max(a, b int) int {
    if a > b {
        return a
    }
    return b
}

func main() {
    weights := []int{2, 2, 3, 4, 5}
    values := []int{3, 4, 5, 8, 10}
    capacity := 7

    maxVal := knapsackDP(weights, values, capacity)
    fmt.Printf("Maximum value that can be obtained: %d\n", maxVal)
}
]];

    Template = Template .. "]]"
    Template = Template .. Template2

    local cursor = vim.fn.getcurpos()
    local line = cursor[2]

    for i, snippetLine in ipairs(vim.fn.split(Template, '\n')) do
        vim.fn.append(line - 1 + i, snippetLine)
    end
end

function ImportLCS()
    local Template = [[
package main

import (
	"fmt"
)

func longestCommonSubsequence(text1 string, text2 string) string {
	m, n := len(text1), len(text2)
	dp := make([][]int, m+1)
	for i := range dp {
		dp[i] = make([]int, n+1)
	}

	for i := 1; i <= m; i++ {
		for j := 1; j <= n; j++ {
			if text1[i-1] == text2[j-1] {
				dp[i][j] = dp[i-1][j-1] + 1
			} else {
				dp[i][j] = max(dp[i-1][j], dp[i][j-1])
			}
		}
	}

	// Reconstruct the LCS
	i, j := m, n
	lcsLen := dp[m][n]
	lcs := make([]byte, lcsLen)

	for i > 0 && j > 0 {
		if text1[i-1] == text2[j-1] {
			lcs[lcsLen-1] = text1[i-1]
			i--
			j--
			lcsLen--
		} else if dp[i-1][j] > dp[i][j-1] {
			i--
		} else {
			j--
		}
	}

	return string(lcs)
}

func max(a, b int) int {
	if a > b {
		return a
	}
	return b
}

func main() {
	text1 := "AGGTAB"
	text2 := "GXTXAYB"
	lcs := longestCommonSubsequence(text1, text2)
	fmt.Printf("Longest Common Subsequence: %s\n", lcs)
}
]]
    local cursor = vim.fn.getcurpos()
    local line = cursor[2]

    for i, snippetLine in ipairs(vim.fn.split(Template, '\n')) do
        vim.fn.append(line - 1 + i, snippetLine)
    end
end

function ImportLIS()
    local Template = [[
package main

import (
	"fmt"
)

func longestIncreasingSubsequence(nums []int) []int {
	if len(nums) == 0 {
		return nil
	}

	dp := make([]int, len(nums))
	parent := make([]int, len(nums))

	maxLength := 1
	endIndex := 0

	for i := 0; i < len(nums); i++ {
		dp[i] = 1
		parent[i] = -1

		for j := 0; j < i; j++ {
			if nums[i] > nums[j] && dp[i] < dp[j]+1 {
				dp[i] = dp[j] + 1
				parent[i] = j
			}
		}

		if dp[i] > maxLength {
			maxLength = dp[i]
			endIndex = i
		}
	}

	// Reconstruct the LIS
	lis := make([]int, 0, maxLength)
	for endIndex != -1 {
		lis = append(lis, nums[endIndex])
		endIndex = parent[endIndex]
	}

	// Reverse the LIS to get the correct order
	reverse(lis)

	return lis
}

func reverse(nums []int) {
	left, right := 0, len(nums)-1
	for left < right {
		nums[left], nums[right] = nums[right], nums[left]
		left++
		right--
	}
}

func main() {
	nums := []int{10, 22, 9, 33, 21, 50, 41, 60, 80}
	lis := longestIncreasingSubsequence(nums)
	fmt.Printf("Longest Increasing Subsequence: %v\n", lis)
}
]]
    local cursor = vim.fn.getcurpos()
    local line = cursor[2]
    for i, snippetLine in ipairs(vim.fn.split(Template, '\n')) do
        vim.fn.append(line - 1 + i, snippetLine)
    end
end

function ImportMinimomCoinChange()
    local Template = [[
package main

import (
	"fmt"
	"math"
)

func minCoins(coins []int, amount int) int {
	// Create a slice to store minimum coin counts for each amount from 0 to 'amount'
	dp := make([]int, amount+1)

	// Initialize the values in the dp slice to a maximum value (impossible value)
	for i := range dp {
		dp[i] = math.MaxInt32
	}

	// Base case: 0 coins needed to make an amount of 0
	dp[0] = 0

	// Iterate through all possible amounts from 1 to 'amount'
	for i := 1; i <= amount; i++ {
		// Try all coin denominations
		for _, coin := range coins {
			// Check if the coin can be used to make the current amount 'i'
			if i-coin >= 0 {
				// If using the current coin reduces the number of coins needed, update dp[i]
				dp[i] = min(dp[i], dp[i-coin]+1)
			}
		}
	}

	// If dp[amount] is still at its initial value (impossible value), it means it's not possible to make the amount.
	if dp[amount] == math.MaxInt32 {
		return -1
	}

	return dp[amount]
}

func min(a, b int) int {
	if a < b {
		return a
	}
	return b
}

func main() {
	coins := []int{1, 2, 5}
	amount := 11
	minimumCoins := minCoins(coins, amount)

	if minimumCoins == -1 {
		fmt.Println("It's not possible to make the amount with the given coins.")
	} else {
		fmt.Printf("Minimum number of coins needed to make %d: %d\n", amount, minimumCoins)
	}
}
  ]]
    local cursor = vim.fn.getcurpos()
    local line = cursor[2]
    for i, snippetLine in ipairs(vim.fn.split(Template, '\n')) do
        vim.fn.append(line - 1 + i, snippetLine)
    end
end

function ImportMatrixChainMultiplication()
    local Template = [[
package main

import (
	"fmt"
)

func matrixChainOrder(p []int) int {
	n := len(p) - 1 // Number of matrices
	m := make([][]int, n)
	for i := range m {
		m[i] = make([]int, n)
	}

	// `m[i][j]` will store the minimum number of scalar multiplications needed
	// to compute the matrix product A[i]A[i+1]...A[j]
	for length := 2; length <= n; length++ {
		for i := 0; i <= n-length+1; i++ {
			j := i + length - 1
			m[i][j] = 1 << 31 // Initialize to a large value (maximum integer)
			for k := i; k < j; k++ {
				cost := m[i][k] + m[k+1][j] + p[i]*p[k+1]*p[j+1]
				if cost < m[i][j] {
					m[i][j] = cost
				}
			}
		}
	}

	return m[0][n-1] // Minimum number of scalar multiplications needed for the entire chain
}

func main() {
	// Example: Suppose you have matrices with dimensions 10x30, 30x5, 5x60
	// The 'p' array represents the dimensions of these matrices.
	p := []int{10, 30, 5, 60}
	minMultiplications := matrixChainOrder(p)
	fmt.Printf("Minimum number of scalar multiplications: %d\n", minMultiplications)
}

    ]]

    local cursor = vim.fn.getcurpos()
    local line = cursor[2]
    for i, snippetLine in ipairs(vim.fn.split(Template, '\n')) do
        vim.fn.append(line - 1 + i, snippetLine)
    end
end

function ImportEditDistanceAlgo()
    local Template = [[
package main

import (
	"fmt"
)

func minDistance(word1 string, word2 string) int {
	m, n := len(word1), len(word2)
	// Create a 2D slice to store the edit distances
	dp := make([][]int, m+1)
	for i := range dp {
		dp[i] = make([]int, n+1)
	}

	// Initialize the first row and first column
	for i := 0; i <= m; i++ {
		dp[i][0] = i
	}
	for j := 0; j <= n; j++ {
		dp[0][j] = j
	}

	// Fill in the matrix
	for i := 1; i <= m; i++ {
		for j := 1; j <= n; j++ {
			cost := 1 // Cost of a single operation (insertion, deletion, or substitution)
			if word1[i-1] == word2[j-1] {
				cost = 0 // Characters match, no need for substitution
			}
			dp[i][j] = min(dp[i-1][j]+1, dp[i][j-1]+1, dp[i-1][j-1]+cost)
		}
	}

	// The bottom-right cell contains the minimum edit distance
	return dp[m][n]
}

func min(a, b, c int) int {
	if a <= b && a <= c {
		return a
	} else if b <= a && b <= c {
		return b
	}
	return c
}

func main() {
	word1 := "intention"
	word2 := "execution"
	distance := minDistance(word1, word2)
	fmt.Printf("Minimum Edit Distance between '%s' and '%s' is %d\n", word1, word2, distance)
}

    ]]

    local cursor = vim.fn.getcurpos()
    local line = cursor[2]
    for i, snippetLine in ipairs(vim.fn.split(Template, '\n')) do
        vim.fn.append(line - 1 + i, snippetLine)
    end
end

function ImportStack()
    local Template = [[
package main

import (
	"fmt"
)

type Stack struct {
	data []interface{}
}

func (s *Stack) Push(item interface{}) {
	s.data = append(s.data, item)
}

func (s *Stack) Pop() interface{} {
	if len(s.data) == 0 {
		return nil // Stack is empty
	}
	item := s.data[len(s.data)-1]
	s.data = s.data[:len(s.data)-1]
	return item
}

func (s *Stack) Peek() interface{} {
	if len(s.data) == 0 {
		return nil // Stack is empty
	}
	return s.data[len(s.data)-1]
}

func (s *Stack) IsEmpty() bool {
	return len(s.data) == 0
}

func main() {
	stack := Stack{}

	// Push elements onto the stack
	stack.Push(1)
	stack.Push(2)
	stack.Push(3)

	// Peek at the top element
	fmt.Println("Peek:", stack.Peek())

	// Pop elements from the stack
	fmt.Println("Pop:", stack.Pop())
	fmt.Println("Pop:", stack.Pop())
	fmt.Println("Pop:", stack.Pop())
	fmt.Println("Pop:", stack.Pop()) // Trying to pop from an empty stack

	// Check if the stack is empty
	fmt.Println("Is Empty:", stack.IsEmpty())
}
]]

    local cursor = vim.fn.getcurpos()
    local line = cursor[2]
    for i, snippetLine in ipairs(vim.fn.split(Template, '\n')) do
        vim.fn.append(line - 1 + i, snippetLine)
    end
end

function ImportQueue()
    local Template = [[
package main

import (
	"fmt"
)

type Queue struct {
	data []interface{}
}

func (q *Queue) Enqueue(item interface{}) {
	q.data = append(q.data, item)
}

func (q *Queue) Dequeue() interface{} {
	if len(q.data) == 0 {
		return nil // Queue is empty
	}
	item := q.data[0]
	q.data = q.data[1:]
	return item
}

func (q *Queue) IsEmpty() bool {
	return len(q.data) == 0
}

func main() {
	queue := Queue{}

	// Enqueue elements
	queue.Enqueue(1)
	queue.Enqueue(2)
	queue.Enqueue(3)

	// Dequeue elements
	fmt.Println("Dequeue:", queue.Dequeue())
	fmt.Println("Dequeue:", queue.Dequeue())
	fmt.Println("Dequeue:", queue.Dequeue())
	fmt.Println("Dequeue:", queue.Dequeue()) // Trying to dequeue from an empty queue

	// Check if the queue is empty
	fmt.Println("Is Empty:", queue.IsEmpty())
}
]]

    local cursor = vim.fn.getcurpos()
    local line = cursor[2]
    for i, snippetLine in ipairs(vim.fn.split(Template, '\n')) do
        vim.fn.append(line - 1 + i, snippetLine)
    end
end

function ImportLinkedList()
    local Template = [[
      package main

import (
	"fmt"
)

// Node represents a single element in the linked list.
type Node struct {
	data interface{}
	next *Node
}

// LinkedList represents the linked list itself.
type LinkedList struct {
	head *Node
}

// Insert adds a new element to the end of the linked list.
func (ll *LinkedList) Insert(data interface{}) {
	newNode := &Node{data: data, next: nil}

	if ll.head == nil {
		ll.head = newNode
		return
	}

	current := ll.head
	for current.next != nil {
		current = current.next
	}
	current.next = newNode
}

// Delete removes the first occurrence of the specified element from the linked list.
func (ll *LinkedList) Delete(data interface{}) {
	if ll.head == nil {
		return
	}

	if ll.head.data == data {
		ll.head = ll.head.next
		return
	}

	current := ll.head
	for current.next != nil && current.next.data != data {
		current = current.next
	}

	if current.next == nil {
		return // Element not found
	}

	current.next = current.next.next
}

// Display prints the elements of the linked list.
func (ll *LinkedList) Display() {
	current := ll.head
	for current != nil {
		fmt.Print(current.data, " ")
		current = current.next
	}
	fmt.Println()
}

func main() {
	ll := LinkedList{}

	// Insert elements
	ll.Insert(1)
	ll.Insert(2)
	ll.Insert(3)
	ll.Insert(4)

	// Display the linked list
	fmt.Print("Linked List: ")
	ll.Display()

	// Delete an element
	ll.Delete(3)

	// Display the linked list after deletion
	fmt.Print("Linked List after deletion: ")
	ll.Display()
}

    ]]

    local cursor = vim.fn.getcurpos()
    local line = cursor[2]
    for i, snippetLine in ipairs(vim.fn.split(Template, '\n')) do
        vim.fn.append(line - 1 + i, snippetLine)
    end
end

function ImportPQ()
    local Template = [[
package main

import (
	"container/heap"
	"fmt"
)

// Item represents an item with a priority in the priority queue.
type Item struct {
	value    interface{}
	priority int
	index    int // Index in the heap
}

// PriorityQueue implements a min-heap priority queue.
type PriorityQueue []*Item

// Len returns the number of items in the priority queue.
func (pq PriorityQueue) Len() int {
	return len(pq)
}

// Less compares two items based on their priorities.
func (pq PriorityQueue) Less(i, j int) bool {
	return pq[i].priority < pq[j].priority
}

// Swap swaps two items in the priority queue.
func (pq PriorityQueue) Swap(i, j int) {
	pq[i], pq[j] = pq[j], pq[i]
	pq[i].index = i
	pq[j].index = j
}

// Push adds an item to the priority queue.
func (pq *PriorityQueue) Push(x interface{}) {
	item := x.(*Item)
	item.index = len(*pq)
	*pq = append(*pq, item)
}

// Pop removes and returns the item with the highest priority from the priority queue.
func (pq *PriorityQueue) Pop() interface{} {
	old := *pq
	n := len(old)
	item := old[n-1]
	item.index = -1
	*pq = old[0 : n-1]
	return item
}

func main() {
	pq := make(PriorityQueue, 0)

	// Insert elements with priorities into the priority queue
	heap.Push(&pq, &Item{value: "Task 1", priority: 3})
	heap.Push(&pq, &Item{value: "Task 2", priority: 1})
	heap.Push(&pq, &Item{value: "Task 3", priority: 2})

	// Pop elements from the priority queue based on their priority
	for pq.Len() > 0 {
		item := heap.Pop(&pq).(*Item)
		fmt.Printf("Priority: %d, Value: %s\n", item.priority, item.value)
	}
}

    ]]

    local cursor = vim.fn.getcurpos()
    local line = cursor[2]
    for i, snippetLine in ipairs(vim.fn.split(Template, '\n')) do
        vim.fn.append(line - 1 + i, snippetLine)
    end
end

function ImportDSU()
    local Template = [[
package main

import (
	"fmt"
)

type DSU struct {
	parent []int
	size   []int
}

func NewDSU(n int) *DSU {
	parent := make([]int, n)
	size := make([]int, n)

	for i := 0; i < n; i++ {
		parent[i] = i
		size[i] = 1
	}

	return &DSU{parent, size}
}

func (dsu *DSU) Find(x int) int {
	if dsu.parent[x] != x {
		dsu.parent[x] = dsu.Find(dsu.parent[x]) // Path compression
	}
	return dsu.parent[x]
}

func (dsu *DSU) Union(x, y int) {
	rootX := dsu.Find(x)
	rootY := dsu.Find(y)

	if rootX != rootY {
		// Union by size/rank
		if dsu.size[rootX] > dsu.size[rootY] {
			dsu.parent[rootY] = rootX
			dsu.size[rootX] += dsu.size[rootY]
		} else {
			dsu.parent[rootX] = rootY
			dsu.size[rootY] += dsu.size[rootX]
		}
	}
}

func main() {
	// Example usage of DSU
	n := 6
	dsu := NewDSU(n)

	// Perform union operations
	dsu.Union(0, 1)
	dsu.Union(1, 2)
	dsu.Union(3, 4)

	// Check if elements are in the same set
	fmt.Println("Are 0 and 2 in the same set?", dsu.Find(0) == dsu.Find(2))
	fmt.Println("Are 2 and 3 in the same set?", dsu.Find(2) == dsu.Find(3))
}

    ]]
    local cursor = vim.fn.getcurpos()
    local line = cursor[2]
    for i, snippetLine in ipairs(vim.fn.split(Template, '\n')) do
        vim.fn.append(line - 1 + i, snippetLine)
    end
end
