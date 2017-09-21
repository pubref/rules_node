/**
 * A mapping between kingdom to phylum
 */
export function getKingdomByPhylum(name: string) {
    switch (name) {
    case "Rhizopoda":
    case "Chlorophyta":
        return "Protista";
    case "Bryophyta":
    case "Anthrophyta":
        return "Plantae";
    case "Porifera":
    case "Chordata":
        return "Animalia";
    default:
        throw new Error("Unknown phylum: " + name);
    }
}
