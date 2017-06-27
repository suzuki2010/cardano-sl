-- | Wrappers on top of communication methods

module Pos.Communication.Methods
       ( sendTx
       , sendVote
       , sendUpdateProposal
       ) where

import           Formatting                 (sformat, (%))
import           System.Wlog                (logInfo)
import           Universum

import           Pos.Binary.Communication   ()
import           Pos.Binary.Core            ()
import           Pos.Binary.Relay           ()
import           Pos.Communication.Message  ()
import           Pos.Communication.Protocol (NodeId, SendActions, MsgType (..))
import           Pos.Communication.Relay    (invReqDataFlowTK)
import           Pos.Crypto                 (hash, hashHexF)
import           Pos.DB.Class               (MonadGState)
import           Pos.Txp.Core.Types         (TxAux (..))
import           Pos.Txp.Network.Types      (TxMsgContents (..))
import           Pos.Update                 (UpId, UpdateProposal, UpdateVote, mkVoteId)
import           Pos.WorkMode.Class         (MinWorkMode)


-- | Send Tx to given address.
sendTx
    :: (MinWorkMode m, MonadGState m)
    => SendActions m -> NodeId -> TxAux -> m ()
sendTx sendActions addr txAux =
    invReqDataFlowTK
        "tx"
        sendActions
        MsgTransaction
        addr
        (hash $ taTx txAux)
        (TxMsgContents txAux)

-- Send UpdateVote to given address.
sendVote
    :: (MinWorkMode m, MonadGState m)
    => SendActions m -> NodeId -> UpdateVote -> m ()
sendVote sendActions addr vote =
    invReqDataFlowTK "UpdateVote" sendActions MsgMPC addr (mkVoteId vote) vote

-- Send UpdateProposal to given address.
sendUpdateProposal
    :: (MinWorkMode m, MonadGState m)
    => SendActions m
    -> NodeId
    -> UpId
    -> UpdateProposal
    -> [UpdateVote]
    -> m ()
sendUpdateProposal sendActions addr upid proposal votes = do
    logInfo $ sformat ("Announcing proposal with id "%hashHexF) upid
    invReqDataFlowTK
        "UpdateProposal"
        sendActions
        MsgMPC
        addr
        upid
        (proposal, votes)
