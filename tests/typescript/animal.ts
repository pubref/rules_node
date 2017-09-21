//const phyla = require("taxonomy/phyla");
//import * as answer from "@pubref/meaning of life";
import { getKingdomByPhylum } from 'taxonomy/phyla';

export abstract class Organism {
    public abstract getKingdom(): string;
}

export class Animal extends Organism {

    protected static readonly PHYLUM = "Chordata";

    constructor(public readonly name: string) {
        super();
    }

    getPhylum(): string {
        return Animal.PHYLUM;
    }

    getKingdom(): string {
        return getKingdomByPhylum(this.getPhylum());
    }

}
