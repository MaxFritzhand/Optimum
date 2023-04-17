//
//  ContentView.swift
//  Optimum
//
//  Created by Max Fritzhand on 4/16/23.
//

import SwiftUI
import Foundation
import AppKit

struct Node: Identifiable, Codable {
    let id = UUID()
    var title: String
    var level: Int
    var children: [Node] = []
}

struct ContentView: View {
    @State private var rootNode = Node(title: "Root", level: 0)
    @State private var nodeTitle: String = ""
    @State private var selectedNodeId: UUID?
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Mind Map Builder")
                .font(.largeTitle)
                .padding()
            
            HStack {
                TextField("Node title", text: $nodeTitle)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(width: 300)
                
                Button(action: addNodeToSelected) {
                    Text("Add Node")
                }
                .padding()
                Button(action: {
                                        if let jsonString = encodeNodeToJSON(node: rootNode) {
                                             print("JSON string: \(jsonString)")
                                            }
//                    let angularCode = generateAngularCodeFromMindMap(rootNode: rootNode)
//                    print("Angular code: \(angularCode)")
//                    saveAngularCodeToFile(code: angularCode, fileName: "mind-map.component.ts")
                }) {
                    Text("Submit")
                }
                .padding()
            }
            .padding()
            
            
            TreeView(node: $rootNode, selectedNodeId: $selectedNodeId)
        }
        .frame(width: 600, height: 400)
    }
    
    private func addNodeToSelected() {
        if let selectedNodeId = selectedNodeId {
            let newNode = Node(title: nodeTitle, level: 0) // Set level to 0 for now
            rootNode = updateNodeWithNewChild(root: rootNode, selectedNodeId: selectedNodeId, newChild: newNode)
        }
    }
    
    private func updateNodeWithNewChild(root: Node, selectedNodeId: UUID, newChild: Node) -> Node {
        if root.id == selectedNodeId {
            var updatedRoot = root
            var mutableNewChild = newChild
            mutableNewChild.level = updatedRoot.level + 1
            updatedRoot.children.append(mutableNewChild)
            return updatedRoot
        } else {
            var updatedRoot = root
            updatedRoot.children = root.children.map { child in
                updateNodeWithNewChild(root: child, selectedNodeId: selectedNodeId, newChild: newChild)
            }
            return updatedRoot
        }
    }
    
    private func deleteSelectedNode(node: Node) -> Node? {
        if node.id == selectedNodeId {
            return nil
        } else {
            var updatedNode = node
            updatedNode.children = node.children.compactMap { child in
                deleteSelectedNode(node: child)
            }
            return updatedNode
        }
    }
    // New function to encode a Node object to JSON string
    private func encodeNodeToJSON(node: Node) -> String? {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        
        do {
            let data = try encoder.encode(node)
            let jsonString = String(data: data, encoding: .utf8)
            return jsonString
        } catch {
            print("Error encoding node to JSON: \(error)")
            return nil
        }
    }
    // New function to generate Angular NGX code based on the mind map structure
    private func generateAngularCodeFromMindMap(rootNode: Node) -> String {
        let angularImports = """
            import { Component } from '@angular/core';
            
            """
        
        let angularComponentDeclaration = """
            @Component({
              selector: 'app-mind-map',
              templateUrl: './mind-map.component.html',
              styleUrls: ['./mind-map.component.scss']
            })
            export class MindMapComponent {
            """
        
        let nodesArray = generateNodeArrayCode(node: rootNode, indentation: "  ")
        
        let angularComponentClosing = """
            }
            """
        
        return angularImports + angularComponentDeclaration + nodesArray + angularComponentClosing
    }
    
    private func generateNodeArrayCode(node: Node, indentation: String) -> String {
        var code = "\(indentation)public node\(node.id.uuidString.replacingOccurrences(of: "-", with: "")) = { title: '\(node.title)', children: [\n"
        
        for child in node.children {
            code += generateNodeArrayCode(node: child, indentation: indentation + "  ")
            code += ",\n"
        }
        
        code += "\(indentation)}];\n"
        
        return code
    }
    
    private func saveAngularCodeToFile(code: String, fileName: String) {
        let savePanel = NSSavePanel()
        savePanel.title = "Save Angular Code"
        savePanel.nameFieldStringValue = "mind-map.component.ts"
        savePanel.allowedFileTypes = ["ts"]
        savePanel.canCreateDirectories = true
        savePanel.directoryURL = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first?.appendingPathComponent("OptimumMindMap")
        
        savePanel.begin { result in
            if result == .OK, let fileUrl = savePanel.url {
                do {
                    try code.write(to: fileUrl, atomically: true, encoding: .utf8)
                    print("Angular code saved to file: \(fileUrl)")
                } catch {
                    print("Error saving Angular code to file: \(error)")
                }
            } else {
                print("User did not save the file.")
            }
        }
    }
}

struct TreeView: View {
    @Binding var node: Node
    @Binding var selectedNodeId: UUID?
    @State private var isSelected: Bool = false
    @State private var isEditing: Bool = false

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Button(action: {
                    if isSelected {
                        selectedNodeId = nil
                    } else {
                        selectedNodeId = node.id
                    }
                    isSelected.toggle()
                }) {
                    Text(isSelected ? "✅" : "🔲")
                }

                if isEditing {
                    TextField("Edit title", text: $node.title)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(width: 200)
                } else {
                    Text(node.title)
                        .padding(.leading, CGFloat(node.level) * 20)
                }

                if isSelected {
                    Button(action: {
                        node.level += 1
                    }) {
                        Text("⬇️")
                    }

                    Button(action: {
                        if node.level > 0 {
                            node.level -= 1
                        }
                    }) {
                        Text("⬆️")
                    }

                    Button(action: {
                        isEditing.toggle()
                    }) {
                        Text(isEditing ? "Save" : "Edit")
                    }

                    Button(action: {
                        var rootNodeCopy = node
                        if let parentNodeChildrenBinding = findParentNodeChildrenBinding(root: rootNodeCopy, nodeId: selectedNodeId) {
                            moveNode(direction: -1, parentNodeChildren: parentNodeChildrenBinding)
                        }
                    }) {
                        Text("Move Up")
                    }

                    Button(action: {
                        var rootNodeCopy = node
                        if let parentNodeChildrenBinding = findParentNodeChildrenBinding(root: rootNodeCopy, nodeId: selectedNodeId) {
                          moveNode(direction: 1, parentNodeChildren: parentNodeChildrenBinding)
                        }
                    }) {
                        Text("Move Down")
                    }

                    Button(action: {
                        selectedNodeId = nil
                        isSelected = false
                        node = deleteSelectedNode(node: node) ?? node
                    }) {
                        Text("Delete")
                    }
                }
            }

            ForEach(node.children) { child in
                TreeView(node: Binding(
                    get: { child },
                    set: { newValue in
                        if let index = node.children.firstIndex(where: { $0.id == newValue.id }) {
                            node.children[index] = newValue
                        }
                    }
                ), selectedNodeId: $selectedNodeId)
            }
        }
    }
    // New function to delete a node with the given ID
    private func deleteSelectedNode(node: Node) -> Node? {
        if node.id == selectedNodeId {
            return nil
        } else {
            var updatedNode = node
            updatedNode.children = node.children.compactMap { child in
                deleteSelectedNode(node: child)
            }
            return updatedNode
        }
    }
    
    // Updated moveNode function
    private func moveNode(direction: Int, parentNodeChildren: Binding<[Node]>) {
        if let currentIndex = parentNodeChildren.wrappedValue.firstIndex(where: { $0.id == node.id }) {
            let newIndex = currentIndex + direction
            if newIndex >= 0 && newIndex < parentNodeChildren.wrappedValue.count {
                parentNodeChildren.wrappedValue.swapAt(currentIndex, newIndex)
            }
        }
    }
    



    private func findParentNodeChildrenBinding(root: Node, nodeId: UUID?) -> Binding<[Node]>? {
        if let nodeId = nodeId, root.children.contains(where: { $0.id == nodeId }) {
            return Binding(
                get: { root.children },
                set: { newValue in
                    if let index = node.children.firstIndex(where: { $0.id == nodeId }) {
                        node.children[index].children = newValue
                    }
                }
            )
        } else {
            for index in root.children.indices {
                if let parentNodeChildrenBinding = findParentNodeChildrenBinding(root: root.children[index], nodeId: nodeId) {
                    return parentNodeChildrenBinding
                }
            }
        }
        return nil
    }
}

    
    struct ContentView_Previews: PreviewProvider {
        static var previews: some View {
            ContentView()
        }
    }

