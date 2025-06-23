export type itemEntry = {
    LayoutOrder: number, 
    tool: Tool
}

export type StandardLootableObject = {
    Space: number,
    items: {
        [Tool]: {
            LayoutOrder: number,
            isGrabbed: boolean
        }
    }
}

return nil