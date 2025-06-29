export type FilledSlotsData = {
    [string]: Tool? -- string will be a number in the form of a string which'll represent the Layout Order
}

export type StandardLootableObject = {
    _itself: Model | Tool,
    Space: number,
    _numberOfItems: number,
    FilledSlotsData: FilledSlotsData,
    DataChangeReplicatorRemote: RemoteEvent
}

export type dataChangeRequestPacket = {
    LayoutOrder: number,
    lootTool: Tool?,
    substituteTool: Tool?
}

export type dropRequest_Data = {

}

return nil